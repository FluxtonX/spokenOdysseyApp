package com.spokenodyssey.app

import android.app.Activity
import android.app.Application
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.oudmon.ble.base.bluetooth.BleAction
import com.oudmon.ble.base.bluetooth.BleBaseControl
import com.oudmon.ble.base.bluetooth.BleOperateManager
import com.oudmon.ble.base.bluetooth.DeviceManager
import com.oudmon.ble.base.bluetooth.QCBluetoothCallbackCloneReceiver
import com.oudmon.ble.base.communication.LargeDataHandler
import com.oudmon.ble.base.communication.bigData.resp.GlassModelControlResponse
import com.oudmon.ble.base.communication.bigData.resp.GlassesDeviceNotifyListener
import com.oudmon.ble.base.communication.bigData.resp.GlassesDeviceNotifyRsp
import com.oudmon.ble.base.communication.bigData.resp.VolumeControlResponse
import com.oudmon.ble.base.scan.BleScannerHelper
import com.oudmon.ble.base.scan.ScanRecord
import com.oudmon.ble.base.scan.ScanWrapperCallback
import com.oudmon.wifi.GlassesControl
import com.oudmon.wifi.WifiP2pManagerSingleton
import com.oudmon.wifi.bean.GlassAlbumEntity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Flutter bridge for the HeyCyan / QC glasses SDK (LIB_GLASSES_SDK).
 *
 * Protocol notes (from the SDK's own GlassesControl.importAlbum logic and the iOS QCSDK):
 *  - Mode commands are `glassesControl([0x02, 0x01, mode])`. The reply has dataType 1;
 *    errorCode != 0 means the glasses ACCEPTED the command, errorCode == 0 means they REFUSED
 *    it and `workTypeIng` is the mode they are busy in.
 *  - The SDK keeps a single reply slot for every glassesControl call, so commands must be sent
 *    one at a time (see [enqueueControl]).
 *  - After a Wi-Fi import the SDK keeps sending a transfer heartbeat forever and never leaves
 *    transfer mode, which makes the glasses refuse capture commands. [stopSdkTransfer] ends it.
 */
class GlassesPlatformPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val ALBUM_DIR = "DCIM_1"
        private const val PCM_SAMPLE_RATE = 16000 // GlassesControl.calculatePCMPlaybackDuration

        // QCOperatorDeviceMode values
        const val MODE_PHOTO = 0x01
        const val MODE_VIDEO = 0x02
        const val MODE_VIDEO_STOP = 0x03
        const val MODE_TRANSFER = 0x04
        const val MODE_AUDIO = 0x08
        const val MODE_TRANSFER_STOP = 0x09
        const val MODE_AUDIO_STOP = 0x0c
        const val MODE_FIND_DEVICE = 0x0d

        private const val CONTROL_TIMEOUT_MS = 4000L
        private const val IMPORT_HANDSHAKE_MS = 12000L

        private var sdkInitialized = false
        private var glassesControlInitialized = false
    }

    private var context: Context? = null
    private var activity: Activity? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val mediaExecutor = Executors.newSingleThreadExecutor()
    private var bleReceiver: BroadcastReceiver? = null
    private var systemBtReceiver: BroadcastReceiver? = null
    private var audioLink: GlassesAudioLink? = null

    /** True while a Wi-Fi transfer may be active on the glasses (set by importAlbum). */
    private var transferActive = false
    private var importHandshake = false
    private val importHandshakeTimeout = Runnable { finishImportHandshake() }
    private var lastVolume: VolumeControlResponse? = null

    // ───────────────────────────── Lifecycle ─────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.fluxtonx.spokenodyssey/glasses")
        methodChannel?.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "com.fluxtonx.spokenodyssey/glasses_events")
        eventChannel?.setStreamHandler(this)
        initSDK(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        val ctx = context
        if (ctx != null) {
            bleReceiver?.let {
                try { LocalBroadcastManager.getInstance(ctx).unregisterReceiver(it) } catch (_: Exception) {}
            }
            systemBtReceiver?.let {
                try { ctx.unregisterReceiver(it) } catch (_: Exception) {}
            }
        }
        try { LargeDataHandler.getInstance().removeBatteryCallBack("flutter") } catch (_: Throwable) {}
        audioLink?.stop()
        audioLink = null
        mainHandler.removeCallbacksAndMessages(null)
        bleReceiver = null
        systemBtReceiver = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }

    private fun app(): Application? =
        (context?.applicationContext as? Application) ?: (activity?.application)

    private fun albumDir(): File {
        val base = app()?.getExternalFilesDir("") ?: context?.filesDir ?: File("/")
        return File(base, ALBUM_DIR).apply { if (!exists()) mkdirs() }
    }

    // ───────────────────────────── SDK init ─────────────────────────────

    private fun initSDK(ctx: Context) {
        val app = (ctx as? Application) ?: (ctx.applicationContext as? Application) ?: return
        try {
            if (!sdkInitialized) {
                LargeDataHandler.getInstance()
                BleOperateManager.getInstance(app)
                BleOperateManager.getInstance().setApplication(app)
                BleOperateManager.getInstance().init()
                BleBaseControl.getInstance(app).setmContext(app)
                try { com.androidnetworking.AndroidNetworking.initialize(app) } catch (t: Throwable) { t.printStackTrace() }
                sdkInitialized = true
            }
        } catch (t: Throwable) {
            t.printStackTrace()
        }
        registerBleReceiver(app)
        registerSystemBluetoothReceiver(app)
        registerDeviceNotifications()
        audioLink = GlassesAudioLink(app, mainHandler) { payload ->
            val event = payload["event"] as? String ?: "audioState"
            sendEvent(event, payload - "event")
        }.also { it.start() }
    }

    private fun registerBleReceiver(app: Application) {
        bleReceiver = object : QCBluetoothCallbackCloneReceiver() {
            override fun connectStatue(device: BluetoothDevice?, connected: Boolean) {
                if (device != null && connected) {
                    try {
                        if (!device.name.isNullOrEmpty()) DeviceManager.getInstance().deviceName = device.name
                        if (!device.address.isNullOrEmpty()) DeviceManager.getInstance().deviceAddress = device.address
                    } catch (_: SecurityException) {}
                } else if (!connected) {
                    resetControlQueue()
                    transferActive = false
                    audioLink?.reset()
                    sendEvent("connectionStateChanged", mapOf("state" to "disconnected"))
                }
            }

            override fun onServiceDiscovered() {
                // The SDK only accepts commands after this callback (see vendor sample).
                try {
                    LargeDataHandler.getInstance().initEnable()
                    BleOperateManager.getInstance().isReady = true
                } catch (t: Throwable) { t.printStackTrace() }

                sendEvent("connectionStateChanged", mapOf(
                    "state" to "connected",
                    "name" to (DeviceManager.getInstance().deviceName ?: ""),
                    "address" to (DeviceManager.getInstance().deviceAddress ?: "")
                ))

                mainHandler.postDelayed({
                    try {
                        LargeDataHandler.getInstance().syncTime { _, _ -> }
                        LargeDataHandler.getInstance().syncBattery()
                    } catch (t: Throwable) { t.printStackTrace() }
                }, 400)
                mainHandler.postDelayed({
                    audioLink?.refreshStatus { status -> sendEvent("audioState", status) }
                }, 6000)
            }
        }
        LocalBroadcastManager.getInstance(app).registerReceiver(bleReceiver!!, BleAction.getIntentFilter())
    }

    /** Same role as BluetoothReceiver in the sample: react to the phone's Bluetooth being toggled. */
    private fun registerSystemBluetoothReceiver(app: Application) {
        systemBtReceiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                if (intent.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
                when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1)) {
                    BluetoothAdapter.STATE_OFF -> {
                        try {
                            BleOperateManager.getInstance().setBluetoothTurnOff(false)
                            BleOperateManager.getInstance().disconnect()
                        } catch (t: Throwable) { t.printStackTrace() }
                        resetControlQueue()
                        sendEvent("bluetoothStateChanged", mapOf("enabled" to false))
                        sendEvent("connectionStateChanged", mapOf("state" to "disconnected"))
                    }
                    BluetoothAdapter.STATE_ON -> {
                        sendEvent("bluetoothStateChanged", mapOf("enabled" to true))
                        try {
                            BleOperateManager.getInstance().setBluetoothTurnOff(true)
                            val mac = DeviceManager.getInstance().deviceAddress
                            if (!mac.isNullOrEmpty()) {
                                BleOperateManager.getInstance().reConnectMac = mac
                                BleOperateManager.getInstance().connectDirectly(mac)
                                sendEvent("connectionStateChanged", mapOf("state" to "connecting", "address" to mac))
                            }
                        } catch (t: Throwable) { t.printStackTrace() }
                    }
                }
            }
        }
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            app.registerReceiver(systemBtReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            app.registerReceiver(systemBtReceiver, filter)
        }
    }

    private fun registerDeviceNotifications() {
        try {
            LargeDataHandler.getInstance().addBatteryCallBack("flutter") { _, response ->
                if (response != null) {
                    sendEvent("batteryUpdated", mapOf("battery" to response.battery, "isCharging" to response.isCharging))
                }
            }
            LargeDataHandler.getInstance().addOutDeviceListener(100, object : GlassesDeviceNotifyListener() {
                override fun parseData(cmdType: Int, response: GlassesDeviceNotifyRsp) {
                    val data = response.loadData ?: return
                    if (data.size < 8) return
                    when (data[6].toInt()) {
                        0x05 -> if (data.size > 8) sendEvent("batteryUpdated", mapOf(
                            "battery" to data[7].toInt(),
                            "isCharging" to (data[8].toInt() == 1)
                        ))
                        0x0d -> if (data[7].toInt() == 1) {
                            sendEvent("connectionStateChanged", mapOf("state" to "unbound"))
                        }
                        0x0e -> sendEvent("deviceAlert", mapOf("type" to "storageFull"))
                        0x12 -> if (data.size > 19) sendEvent("volumeChanged", mapOf(
                            "music" to data[10].toInt(),
                            "call" to data[14].toInt(),
                            "system" to data[18].toInt()
                        ))
                    }
                }
            })
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    // ───────────────────────────── Control queue ─────────────────────────────

    private class ControlJob(
        val cmd: ByteArray,
        val expectType: Int,
        val done: (GlassModelControlResponse?) -> Unit,
    )

    private val controlQueue = ArrayDeque<ControlJob>()
    private var controlBusy = false

    /** Runs glassesControl commands one at a time; the SDK only keeps one reply callback. */
    private fun enqueueControl(cmd: ByteArray, expectType: Int, done: (GlassModelControlResponse?) -> Unit) {
        mainHandler.post {
            controlQueue.addLast(ControlJob(cmd, expectType, done))
            pumpControl()
        }
    }

    private fun pumpControl() {
        if (controlBusy || importHandshake) return
        val job = controlQueue.removeFirstOrNull() ?: return
        controlBusy = true
        val finished = AtomicBoolean(false)
        lateinit var timeout: Runnable
        val finish: (GlassModelControlResponse?) -> Unit = { resp ->
            if (finished.compareAndSet(false, true)) {
                mainHandler.post {
                    mainHandler.removeCallbacks(timeout)
                    controlBusy = false
                    try { job.done(resp) } catch (t: Throwable) { t.printStackTrace() }
                    pumpControl()
                }
            }
        }
        timeout = Runnable { finish(null) }
        mainHandler.postDelayed(timeout, CONTROL_TIMEOUT_MS)
        try {
            LargeDataHandler.getInstance().glassesControl(job.cmd) { _, resp ->
                if (resp != null && resp.dataType == job.expectType) finish(resp)
            }
        } catch (t: Throwable) {
            t.printStackTrace()
            finish(null)
        }
    }

    private fun resetControlQueue() {
        mainHandler.post {
            val pending = controlQueue.toList()
            controlQueue.clear()
            pending.forEach { try { it.done(null) } catch (_: Throwable) {} }
        }
    }

    private fun finishImportHandshake() {
        mainHandler.removeCallbacks(importHandshakeTimeout)
        if (importHandshake) {
            importHandshake = false
            pumpControl()
        }
    }

    /**
     * Sends a mode command and reports `{ok, busyMode, timeout}`.
     * If the glasses are stuck in transfer mode, the transfer is ended and the command retried once.
     */
    private fun setMode(mode: Int, allowTransferRecovery: Boolean = true, onResult: (Map<String, Any?>) -> Unit) {
        enqueueControl(byteArrayOf(0x02, 0x01, mode.toByte()), 1) { resp ->
            when {
                resp == null -> onResult(mapOf("ok" to false, "timeout" to true, "busyMode" to null))
                resp.errorCode != 0 -> {
                    sendEvent("workState", mapOf("mode" to mode, "source" to "command"))
                    onResult(mapOf("ok" to true, "timeout" to false, "busyMode" to null))
                }
                else -> {
                    val busy = resp.workTypeIng
                    if (busy == MODE_TRANSFER && allowTransferRecovery && mode != MODE_TRANSFER_STOP) {
                        stopSdkTransfer {
                            mainHandler.postDelayed({ setMode(mode, false, onResult) }, 1200)
                        }
                    } else {
                        onResult(mapOf("ok" to false, "timeout" to false, "busyMode" to busy))
                    }
                }
            }
        }
    }

    /**
     * Ends a Wi-Fi transfer cleanly: stops the SDK's endless transfer heartbeat,
     * drops the Wi-Fi P2P link and tells the glasses to leave transfer mode.
     */
    private fun stopSdkTransfer(then: (() -> Unit)? = null) {
        val app = app()
        if (app != null) {
            try {
                val control = GlassesControl.getInstance(app)
                if (control != null) {
                    val cls = control.javaClass
                    val handler = cls.getDeclaredField("handler").apply { isAccessible = true }.get(control) as? Handler
                    for (name in listOf("heartbeatRunnable", "timeoutRunnable", "p2pConnectFailRunnable")) {
                        val r = cls.getDeclaredField(name).apply { isAccessible = true }.get(control) as? Runnable
                        if (r != null) handler?.removeCallbacks(r)
                    }
                    cls.getDeclaredField("importing").apply { isAccessible = true }.setBoolean(control, false)
                }
            } catch (t: Throwable) {
                t.printStackTrace()
            }
            try { WifiP2pManagerSingleton.getInstance(app).cancelP2pConnection() } catch (t: Throwable) { t.printStackTrace() }
        }
        transferActive = false
        finishImportHandshake()
        enqueueControl(byteArrayOf(0x02, 0x01, MODE_TRANSFER_STOP.toByte()), 1) {
            sendEvent("workState", mapOf("mode" to 0, "source" to "transferStop"))
            then?.invoke()
        }
    }

    // ───────────────────────────── Methods ─────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initializeSDK" -> result.success(true)
                "getConnectedDevice" -> getConnectedDevice(result)
                "startScan" -> startScan(result)
                "stopScan" -> {
                    BleScannerHelper.getInstance().stopScan(context)
                    result.success(true)
                }
                "enableBluetooth" -> enableBluetooth(result)
                "isBluetoothEnabled" -> result.success(BluetoothAdapter.getDefaultAdapter()?.isEnabled == true)
                "connectDevice" -> {
                    val address = call.argument<String>("address")
                    if (address.isNullOrEmpty()) {
                        result.error("INVALID_ADDRESS", "Device address is required", null)
                        return
                    }
                    try { BleScannerHelper.getInstance().stopScan(context) } catch (_: Throwable) {}
                    call.argument<String>("name")?.takeIf { it.isNotEmpty() }?.let {
                        DeviceManager.getInstance().deviceName = it
                    }
                    BleOperateManager.getInstance().connectDirectly(address)
                    sendEvent("connectionStateChanged", mapOf("state" to "connecting", "address" to address))
                    result.success(true)
                }
                "disconnectDevice" -> {
                    if (transferActive) stopSdkTransfer()
                    BleOperateManager.getInstance().unBindDevice()
                    resetControlQueue()
                    sendEvent("connectionStateChanged", mapOf("state" to "disconnected"))
                    result.success(true)
                }
                "syncTime" -> {
                    LargeDataHandler.getInstance().syncTime { _, _ -> }
                    result.success(true)
                }
                "getBatteryLevel" -> {
                    LargeDataHandler.getInstance().syncBattery()
                    result.success(true)
                }
                "setDeviceMode" -> {
                    val mode = call.argument<Int>("mode") ?: return result.error("INVALID_MODE", "mode is required", null)
                    setMode(mode) { res -> mainHandler.post { result.success(res) } }
                }
                // Legacy method names kept for compatibility.
                "takePhoto" -> setMode(MODE_PHOTO) { res -> mainHandler.post { result.success(res) } }
                "toggleRecording" -> {
                    val start = call.argument<Boolean>("start") ?: true
                    setMode(if (start) MODE_VIDEO else MODE_VIDEO_STOP) { res -> mainHandler.post { result.success(res) } }
                }
                "toggleVoiceRecording" -> {
                    val start = call.argument<Boolean>("start") ?: true
                    setMode(if (start) MODE_AUDIO else MODE_AUDIO_STOP) { res -> mainHandler.post { result.success(res) } }
                }
                "endTransfer" -> stopSdkTransfer { mainHandler.post { result.success(true) } }
                "getMediaCount" -> getMediaCount(result)
                "importAlbum" -> importAlbum(result)
                "getAlbumDirectory" -> result.success(albumDir().absolutePath)
                "repairAlbum" -> repairAlbum(result)
                "getAudioStatus" -> {
                    val link = audioLink
                    if (link == null) result.success(mapOf("state" to "unavailable"))
                    else link.refreshStatus { status -> mainHandler.post { result.success(status) } }
                }
                "connectAudio" -> {
                    val link = audioLink
                    if (link == null) result.success(mapOf("state" to "failed", "reason" to "unavailable"))
                    else link.connect { status -> mainHandler.post { result.success(status) } }
                }
                "openBluetoothSettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        (activity ?: context)?.startActivity(intent)
                        result.success(true)
                    } catch (t: Throwable) {
                        result.success(false)
                    }
                }
                "getDeviceSettings" -> getDeviceSettings(result)
                "setWearDetection" -> {
                    val on = call.argument<Boolean>("enabled") ?: true
                    replyOnce(result, mapOf("ok" to false)) { reply ->
                        LargeDataHandler.getInstance().wearCheck(true, on) { _, rsp ->
                            reply(mapOf("ok" to (rsp != null), "enabled" to (rsp?.isOpen ?: on)))
                        }
                    }
                }
                "setVoiceWakeup" -> {
                    val on = call.argument<Boolean>("enabled") ?: true
                    replyOnce(result, mapOf("ok" to false)) { reply ->
                        LargeDataHandler.getInstance().aiVoiceWake(true, on) { _, rsp ->
                            reply(mapOf("ok" to (rsp != null), "enabled" to (rsp?.isOpen ?: on)))
                        }
                    }
                }
                "setVolume" -> setVolume(call, result)
                "getVideoConfig" -> {
                    enqueueControl(byteArrayOf(0x02, 0x02), 2) { resp ->
                        val payload = resp?.let {
                            mapOf("angle" to it.videoAngle, "duration" to it.videoDuration)
                        }
                        mainHandler.post { result.success(payload) }
                    }
                }
                "setVideoConfig" -> {
                    val angle = call.argument<Int>("angle") ?: 0
                    val duration = call.argument<Int>("duration") ?: 180
                    val payload = byteArrayOf(
                        0x02,
                        0x02,
                        angle.toByte(),
                        ((duration shr 8) and 0xFF).toByte(),
                        (duration and 0xFF).toByte()
                    )
                    enqueueControl(payload, 2) { resp ->
                        mainHandler.post { result.success(mapOf("ok" to (resp != null))) }
                    }
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.error("GLASSES_ERROR", t.localizedMessage ?: t.toString(), null)
        }
    }

    /** Replies to Flutter exactly once: with the SDK answer or [fallback] after a timeout. */
    private fun replyOnce(
        result: MethodChannel.Result,
        fallback: Any?,
        timeoutMs: Long = 4000,
        block: (reply: (Any?) -> Unit) -> Unit,
    ) {
        val done = AtomicBoolean(false)
        val timeout = Runnable { if (done.compareAndSet(false, true)) result.success(fallback) }
        mainHandler.postDelayed(timeout, timeoutMs)
        try {
            block { value ->
                if (done.compareAndSet(false, true)) {
                    mainHandler.removeCallbacks(timeout)
                    mainHandler.post { result.success(value) }
                }
            }
        } catch (t: Throwable) {
            if (done.compareAndSet(false, true)) {
                mainHandler.removeCallbacks(timeout)
                result.success(fallback)
            }
        }
    }

    private fun getConnectedDevice(result: MethodChannel.Result) {
        if (BleOperateManager.getInstance().isConnected) {
            result.success(mapOf(
                "isConnected" to true,
                "name" to (DeviceManager.getInstance().deviceName ?: ""),
                "address" to (DeviceManager.getInstance().deviceAddress ?: "")
            ))
        } else {
            result.success(mapOf("isConnected" to false))
        }
    }

    private fun startScan(result: MethodChannel.Result) {
        BleScannerHelper.getInstance().reSetCallback()
        BleScannerHelper.getInstance().scanDevice(context, null, object : ScanWrapperCallback {
            override fun onStart() { sendEvent("scanState", mapOf("scanning" to true)) }
            override fun onStop() { sendEvent("scanState", mapOf("scanning" to false)) }
            override fun onLeScan(device: BluetoothDevice?, rssi: Int, scanRecord: ByteArray?) {
                if (device == null) return
                val name = try { device.name } catch (_: SecurityException) { null }
                if (name.isNullOrEmpty()) return
                sendEvent("scanResult", mapOf("name" to name, "address" to device.address, "rssi" to rssi))
            }
            override fun onScanFailed(errorCode: Int) {
                sendEvent("scanState", mapOf("scanning" to false, "error" to errorCode))
            }
            override fun onParsedData(device: BluetoothDevice?, scanRecord: ScanRecord?) {}
            override fun onBatchScanResults(results: MutableList<ScanResult>?) {}
        })
        result.success(true)
    }

    private fun enableBluetooth(result: MethodChannel.Result) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter != null && !adapter.isEnabled) {
            try {
                val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                val act = activity
                if (act != null) {
                    act.startActivityForResult(intent, 300)
                } else {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context?.startActivity(intent)
                }
            } catch (t: Throwable) { t.printStackTrace() }
        }
        result.success(true)
    }

    private fun getMediaCount(result: MethodChannel.Result) {
        if (transferActive) {
            result.success(null)
            return
        }
        enqueueControl(byteArrayOf(0x02, 0x04), 4) { resp ->
            val payload = resp?.let {
                mapOf("images" to it.imageCount, "videos" to it.videoCount, "audio" to it.recordCount)
            }
            mainHandler.post { result.success(payload) }
        }
    }

    // ───────────────────────────── Device settings ─────────────────────────────

    private fun getDeviceSettings(result: MethodChannel.Result) {
        val out = HashMap<String, Any?>()
        val handler = LargeDataHandler.getInstance()
        // Each step has its own reply slot; run them one after another with a short timeout each.
        val steps: List<(next: () -> Unit) -> Unit> = listOf(
            { next ->
                stepWithTimeout(next) { done ->
                    handler.wearFunctionSupport { _, rsp ->
                        if (rsp != null) {
                            out["wearSupported"] = rsp.isWearCheckSupport
                            out["volumeSupported"] = rsp.isVolumeControl
                        }
                        done()
                    }
                }
            },
            { next ->
                stepWithTimeout(next) { done ->
                    handler.wearCheck(false, false) { _, rsp ->
                        if (rsp != null) out["wearDetection"] = rsp.isOpen
                        done()
                    }
                }
            },
            { next ->
                stepWithTimeout(next) { done ->
                    handler.aiVoiceWake(false, false) { _, rsp ->
                        if (rsp != null) out["voiceWakeup"] = rsp.isOpen
                        done()
                    }
                }
            },
            { next ->
                stepWithTimeout(next) { done ->
                    handler.getVolumeControl { _, rsp ->
                        if (rsp != null) {
                            lastVolume = rsp
                            out["volume"] = mapOf(
                                "musicMin" to rsp.minVolumeMusic, "musicMax" to rsp.maxVolumeMusic, "music" to rsp.currVolumeMusic,
                                "callMin" to rsp.minVolumeCall, "callMax" to rsp.maxVolumeCall, "call" to rsp.currVolumeCall,
                                "systemMin" to rsp.minVolumeSystem, "systemMax" to rsp.maxVolumeSystem, "system" to rsp.currVolumeSystem,
                                "mode" to rsp.currVolumeType
                            )
                        }
                        done()
                    }
                }
            },
            { next ->
                stepWithTimeout(next) { done ->
                    handler.syncDeviceInfo { _, info ->
                        if (info != null) {
                            out["firmwareVersion"] = info.firmwareVersion ?: ""
                            out["hardwareVersion"] = info.hardwareVersion ?: ""
                            out["wifiFirmwareVersion"] = info.wifiFirmwareVersion ?: ""
                        }
                        done()
                    }
                }
            },
        )
        fun run(i: Int) {
            if (i >= steps.size) {
                out["address"] = DeviceManager.getInstance().deviceAddress ?: ""
                out["name"] = DeviceManager.getInstance().deviceName ?: ""
                mainHandler.post { result.success(out) }
                return
            }
            steps[i] { run(i + 1) }
        }
        run(0)
    }

    private fun stepWithTimeout(next: () -> Unit, block: (done: () -> Unit) -> Unit) {
        val fired = AtomicBoolean(false)
        val timeout = Runnable { if (fired.compareAndSet(false, true)) next() }
        mainHandler.postDelayed(timeout, 2500)
        val done = {
            if (fired.compareAndSet(false, true)) {
                mainHandler.removeCallbacks(timeout)
                mainHandler.post { next() }
            }
        }
        try { block(done) } catch (t: Throwable) { t.printStackTrace(); done() }
    }

    private fun setVolume(call: MethodCall, result: MethodChannel.Result) {
        val v = lastVolume
        if (v == null) {
            result.success(mapOf("ok" to false))
            return
        }
        val music = call.argument<Int>("music") ?: v.currVolumeMusic
        val callVol = call.argument<Int>("call") ?: v.currVolumeCall
        val system = call.argument<Int>("system") ?: v.currVolumeSystem
        LargeDataHandler.getInstance().setVolumeControl(
            v.minVolumeMusic, v.maxVolumeMusic, music.coerceIn(v.minVolumeMusic, v.maxVolumeMusic),
            v.minVolumeCall, v.maxVolumeCall, callVol.coerceIn(v.minVolumeCall, v.maxVolumeCall),
            v.minVolumeSystem, v.maxVolumeSystem, system.coerceIn(v.minVolumeSystem, v.maxVolumeSystem),
            v.currVolumeType
        )
        // Refresh the cached values so the next change starts from the device's state.
        LargeDataHandler.getInstance().getVolumeControl { _, rsp -> if (rsp != null) lastVolume = rsp }
        result.success(mapOf("ok" to true))
    }

    // ───────────────────────────── Media import ─────────────────────────────

    private fun importAlbum(result: MethodChannel.Result) {
        val app = app()
        if (app == null) {
            result.error("APP_NULL", "Application instance unavailable", null)
            return
        }
        val control = GlassesControl.getInstance(app)
        if (control == null) {
            result.error("IMPORT_ERROR", "Glasses import service unavailable", null)
            return
        }
        val dir = albumDir()
        // initGlasses registers the Wi-Fi P2P receiver + callback: do it only once per process.
        if (!glassesControlInitialized) {
            control.initGlasses(dir.absolutePath)
            glassesControlInitialized = true
        }
        control.setWifiDownloadListener(downloadListener(dir))

        val start = {
            mainHandler.post {
                // importAlbum sends its own glassesControl command; keep our queue quiet meanwhile.
                importHandshake = true
                transferActive = true
                mainHandler.postDelayed(importHandshakeTimeout, IMPORT_HANDSHAKE_MS)
                try {
                    control.importAlbum()
                } catch (t: Throwable) {
                    finishImportHandshake()
                    sendEvent("importProgress", mapOf("status" to "fail", "code" to -1))
                }
            }
        }
        // If an earlier transfer is still open, the glasses would ignore the new request.
        if (transferActive) stopSdkTransfer { mainHandler.postDelayed({ start() }, 1500) } else start()
        result.success(true)
    }

    private fun downloadListener(dir: File) = object : GlassesControl.WifiFilesDownloadListener {
        override fun onGlassesControlSuccess() {
            finishImportHandshake()
            sendEvent("workState", mapOf("mode" to MODE_TRANSFER, "source" to "import"))
            sendEvent("importProgress", mapOf("status" to "started"))
        }
        override fun onGlassesFail(errorCode: Int) {
            finishImportHandshake()
            sendEvent("importProgress", mapOf("status" to "fail", "code" to errorCode))
            stopSdkTransfer()
        }
        override fun wifiSpeed(wifiSpeed: String) {
            sendEvent("importProgress", mapOf("status" to "speed", "speed" to wifiSpeed))
        }
        override fun fileCount(index: Int, total: Int) {
            sendEvent("importProgress", mapOf("status" to "count", "index" to index, "total" to total))
        }
        override fun fileProgress(fileName: String, progress: Int) {
            sendEvent("importProgress", mapOf("status" to "downloading", "file" to fileName, "progress" to progress))
        }
        override fun fileWasDownloadSuccessfully(entity: GlassAlbumEntity) {
            val path = entity.filePath ?: return
            // Files arrive as extension-less bundles (media + gyro/frame data + "Thisadir" index),
            // so the SDK's fileType is unreliable. Unpack and identify the media ourselves.
            mediaExecutor.execute {
                val media = GlassesMediaUnpacker.normalize(File(path), dir)
                if (media != null) {
                    emitNormalized(media)
                } else {
                    sendEvent("importProgress", mapOf("status" to "fileError", "fileType" to 0, "file" to entity.fileName))
                }
            }
        }
        override fun fileDownloadComplete() {
            // Let queued photo checks finish before reporting completion, then leave transfer mode.
            mediaExecutor.execute {
                sendEvent("importProgress", mapOf("status" to "complete"))
                mainHandler.postDelayed({ stopSdkTransfer() }, 2500)
            }
        }
        override fun fileDownloadError(fileType: Int, errorType: Int) {
            sendEvent("importProgress", mapOf("status" to "fileError", "fileType" to fileType, "code" to errorType))
        }
        override fun eisEnd(fileName: String, filePath: String) {}
        override fun eisError(fileName: String, sourcePath: String, errorInfo: String) {}
        override fun recordingToPcm(fileName: String, filePath: String, duration: Int) {
            // 16 kHz/16-bit/mono PCM: wrap it in a WAV header so it can be played.
            mediaExecutor.execute {
                val wav = pcmToWav(filePath) ?: return@execute
                sendEvent("mediaImported", mapOf(
                    "fileName" to wav.name,
                    "filePath" to wav.absolutePath,
                    "fileType" to 3,
                    "duration" to (duration / 1000),
                    "thumbnailPath" to "",
                    "timestamp" to System.currentTimeMillis(),
                    "fileDate" to ""
                ))
            }
        }
        override fun recordingToPcmError(fileName: String, errorInfo: String) {
            sendEvent("importProgress", mapOf("status" to "fileError", "fileType" to 3, "message" to errorInfo))
        }
    }

    private fun emitNormalized(media: GlassesMediaUnpacker.Media) {
        sendEvent("mediaImported", media.toMap())
    }

    /**
     * Unpacks media imported earlier that is still in the raw bundle format and returns
     * every recovered item, so the library can list it. Skips anything still being written.
     */
    private fun repairAlbum(result: MethodChannel.Result) {
        if (transferActive) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        val dir = albumDir()
        mediaExecutor.execute {
            val recovered = GlassesMediaUnpacker.repairFolder(dir).map { it.toMap() }
            mainHandler.post { result.success(recovered) }
        }
    }

    private fun pcmToWav(pcmPath: String): File? {
        return try {
            val pcm = File(pcmPath)
            if (!pcm.exists() || pcm.length() == 0L) return null
            val wav = File(pcm.parentFile, pcm.nameWithoutExtension + ".wav")
            val dataLen = pcm.length().toInt()
            val byteRate = PCM_SAMPLE_RATE * 2
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN).apply {
                put("RIFF".toByteArray()); putInt(36 + dataLen); put("WAVE".toByteArray())
                put("fmt ".toByteArray()); putInt(16); putShort(1); putShort(1)
                putInt(PCM_SAMPLE_RATE); putInt(byteRate); putShort(2); putShort(16)
                put("data".toByteArray()); putInt(dataLen)
            }.array()
            FileOutputStream(wav).use { out ->
                out.write(header)
                FileInputStream(pcm).use { it.copyTo(out) }
            }
            pcm.delete()
            wav
        } catch (t: Throwable) {
            t.printStackTrace()
            null
        }
    }

    // ───────────────────────────── Events ─────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { eventSink = events }
    override fun onCancel(arguments: Any?) { eventSink = null }

    private fun sendEvent(eventName: String, data: Map<String, Any?>) {
        val payload = HashMap<String, Any?>()
        payload["event"] = eventName
        payload.putAll(data)
        mainHandler.post { eventSink?.success(payload) }
    }
}
