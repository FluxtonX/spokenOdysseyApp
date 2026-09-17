package com.spokenodyssey.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanResult
import android.os.Handler
import android.os.Looper
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.oudmon.ble.base.bluetooth.BleAction
import com.oudmon.ble.base.bluetooth.BleOperateManager
import com.oudmon.ble.base.bluetooth.DeviceManager
import com.oudmon.ble.base.bluetooth.QCBluetoothCallbackCloneReceiver
import com.oudmon.wifi.GlassesControl
import com.oudmon.wifi.bean.GlassAlbumEntity
import java.io.File
import com.oudmon.ble.base.communication.LargeDataHandler
import com.oudmon.ble.base.communication.bigData.resp.GlassesDeviceNotifyListener
import com.oudmon.ble.base.communication.bigData.resp.GlassesDeviceNotifyRsp
import com.oudmon.ble.base.scan.BleScannerHelper
import com.oudmon.ble.base.scan.ScanRecord
import com.oudmon.ble.base.scan.ScanWrapperCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GlassesPlatformPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var context: Context? = null
    private var activity: Activity? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var bleReceiver: BroadcastReceiver? = null

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
        if (context != null && bleReceiver != null) {
            try {
                LocalBroadcastManager.getInstance(context!!).unregisterReceiver(bleReceiver!!)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun initSDK(ctx: Context) {
        try {
            val app = (ctx as? android.app.Application) ?: (ctx.applicationContext as? android.app.Application)
            LargeDataHandler.getInstance()
            if (app != null) {
                BleOperateManager.getInstance(app)
                BleOperateManager.getInstance().setApplication(app)
                BleOperateManager.getInstance().init()
            }

            bleReceiver = object : QCBluetoothCallbackCloneReceiver() {
                override fun connectStatue(device: BluetoothDevice?, connected: Boolean) {
                    if (device != null && connected) {
                        if (!device.name.isNullOrEmpty()) {
                            DeviceManager.getInstance().deviceName = device.name
                        }
                        if (!device.address.isNullOrEmpty()) {
                            DeviceManager.getInstance().deviceAddress = device.address
                        }
                    } else if (!connected) {
                        sendEvent("connectionStateChanged", mapOf("state" to "disconnected"))
                    }
                }

                override fun onServiceDiscovered() {
                    try {
                        LargeDataHandler.getInstance().initEnable()
                        BleOperateManager.getInstance().isReady = true
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }

                    val name = DeviceManager.getInstance().deviceName ?: "Spoken Glasses"
                    val address = DeviceManager.getInstance().deviceAddress ?: ""
                    sendEvent("connectionStateChanged", mapOf(
                        "state" to "connected",
                        "name" to name,
                        "address" to address
                    ))

                    try {
                        LargeDataHandler.getInstance().syncBattery()
                        LargeDataHandler.getInstance().syncTime { _, _ -> }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }

            val filter = BleAction.getIntentFilter()
            filter.addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            filter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
            filter.addAction(BleAction.BLE_GATT_CONNECTED)
            filter.addAction(BleAction.BLE_SERVICE_DISCOVERED)
            filter.addAction(BleAction.BLE_GATT_DISCONNECTED)
            LocalBroadcastManager.getInstance(ctx).registerReceiver(bleReceiver!!, filter)

            LargeDataHandler.getInstance().addOutDeviceListener(100, object : GlassesDeviceNotifyListener() {
                override fun parseData(cmdType: Int, response: GlassesDeviceNotifyRsp) {
                    if (response.loadData != null && response.loadData.size > 8) {
                        val subCmd = response.loadData[6].toInt()
                        when (subCmd) {
                            0x05 -> { // Battery update
                                val battery = response.loadData[7].toInt()
                                val charging = response.loadData[8].toInt() == 1
                                sendEvent("batteryUpdated", mapOf(
                                    "battery" to battery,
                                    "isCharging" to charging
                                ))
                            }
                            0x02 -> { // Glasses Photo Capture Event with Flash/LED
                                LargeDataHandler.getInstance().getPictureThumbnails { _, success, data ->
                                    if (data != null && data.isNotEmpty()) {
                                        try {
                                            val app = (context?.applicationContext as? android.app.Application)
                                            val dir = File(app?.getExternalFilesDir(""), "DCIM_1")
                                            if (!dir.exists()) dir.mkdirs()
                                            val photoFile = File(dir, "IMG_${System.currentTimeMillis()}.jpg")
                                            val fos = java.io.FileOutputStream(photoFile)
                                            fos.write(data)
                                            fos.flush()
                                            fos.close()
                                            sendEvent("mediaImported", mapOf(
                                                "fileName" to photoFile.name,
                                                "filePath" to photoFile.absolutePath,
                                                "fileType" to 2,
                                                "duration" to 0
                                            ))
                                        } catch (e: Exception) {
                                            e.printStackTrace()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            })
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initializeSDK" -> {
                result.success(true)
            }

            "getConnectedDevice" -> {
                try {
                    val isConnected = BleOperateManager.getInstance().isConnected
                    val devAddress = DeviceManager.getInstance().deviceAddress
                    val devName = DeviceManager.getInstance().deviceName ?: "Spoken Glasses"
                    if (isConnected || (!devAddress.isNullOrEmpty() && devAddress != "00:00:00:00:00:00")) {
                        result.success(mapOf(
                            "isConnected" to true,
                            "name" to devName,
                            "address" to devAddress
                        ))
                    } else {
                        val adapter = BluetoothAdapter.getDefaultAdapter()
                        val bonded = adapter?.bondedDevices
                        var foundDevice: BluetoothDevice? = null
                        if (bonded != null) {
                            for (dev in bonded) {
                                if (!dev.name.isNullOrEmpty() && (dev.name.startsWith("O_") || dev.name.startsWith("Q_") || dev.name.contains("Glass", ignoreCase = true) || dev.name.contains("Cyan", ignoreCase = true))) {
                                    foundDevice = dev
                                    break
                                }
                            }
                        }
                        if (foundDevice != null) {
                            BleOperateManager.getInstance().connectDirectly(foundDevice.address)
                            result.success(mapOf(
                                "isConnected" to true,
                                "name" to (foundDevice.name ?: "Spoken Glasses"),
                                "address" to foundDevice.address
                            ))
                        } else {
                            result.success(mapOf("isConnected" to false))
                        }
                    }
                } catch (e: Exception) {
                    result.success(mapOf("isConnected" to false))
                }
            }

            "startScan" -> {
                try {
                    BleScannerHelper.getInstance().reSetCallback()
                    BleScannerHelper.getInstance().scanDevice(context, null, object : ScanWrapperCallback {
                        override fun onStart() {}
                        override fun onStop() {}

                        override fun onLeScan(device: BluetoothDevice?, rssi: Int, scanRecord: ByteArray?) {
                            if (device != null && !device.name.isNullOrEmpty()) {
                                sendEvent("scanResult", mapOf(
                                    "name" to device.name,
                                    "address" to device.address,
                                    "rssi" to rssi
                                ))
                            }
                        }

                        override fun onScanFailed(errorCode: Int) {}
                        override fun onParsedData(device: BluetoothDevice?, scanRecord: ScanRecord?) {}
                        override fun onBatchScanResults(results: MutableList<ScanResult>?) {}
                    })
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SCAN_ERROR", e.localizedMessage, null)
                }
            }

            "enableBluetooth" -> {
                try {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter != null && !adapter.isEnabled) {
                        try {
                            LargeDataHandler.getInstance().openBT()
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                        try {
                            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                            val act = activity
                            if (act != null) {
                                act.startActivityForResult(intent, 300)
                            } else {
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context?.startActivity(intent)
                            }
                        } catch (e: SecurityException) {
                            e.printStackTrace()
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ENABLE_BT_ERROR", e.localizedMessage, null)
                }
            }

            "isBluetoothEnabled" -> {
                val adapter = BluetoothAdapter.getDefaultAdapter()
                result.success(adapter?.isEnabled == true)
            }

            "stopScan" -> {
                try {
                    BleScannerHelper.getInstance().stopScan(context)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("STOP_SCAN_ERROR", e.localizedMessage, null)
                }
            }

            "connectDevice" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrEmpty()) {
                    result.error("INVALID_ADDRESS", "Device address is required", null)
                    return
                }
                try {
                    BleOperateManager.getInstance().connectDirectly(address)
                    sendEvent("connectionStateChanged", mapOf("state" to "connecting", "address" to address))
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CONNECT_ERROR", e.localizedMessage, null)
                }
            }

            "disconnectDevice" -> {
                try {
                    BleOperateManager.getInstance().unBindDevice()
                    sendEvent("connectionStateChanged", mapOf("state" to "disconnected"))
                    result.success(true)
                } catch (e: Exception) {
                    result.error("DISCONNECT_ERROR", e.localizedMessage, null)
                }
            }

            "syncTime" -> {
                try {
                    LargeDataHandler.getInstance().syncTime { _, _ -> }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SYNC_TIME_ERROR", e.localizedMessage, null)
                }
            }

            "getBatteryLevel" -> {
                try {
                    LargeDataHandler.getInstance().syncBattery()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("BATTERY_ERROR", e.localizedMessage, null)
                }
            }

            "takePhoto" -> {
                try {
                    // Send photo command to glasses storage
                    LargeDataHandler.getInstance().glassesControl(byteArrayOf(0x02, 0x01, 0x01)) { _, _ -> }
                    // Send snapshot & LED indicator command
                    val cmdData = byteArrayOf(0x02, 0x01, 0x06, 0x02, 0x02, 0x02)
                    LargeDataHandler.getInstance().glassesControl(cmdData) { _, resp ->
                        LargeDataHandler.getInstance().getPictureThumbnails { _, success, data ->
                            if (data != null && data.isNotEmpty()) {
                                try {
                                    val app = (context?.applicationContext as? android.app.Application)
                                    val dir = File(app?.getExternalFilesDir(""), "DCIM_1")
                                    if (!dir.exists()) dir.mkdirs()
                                    val photoFile = File(dir, "IMG_${System.currentTimeMillis()}.jpg")
                                    val fos = java.io.FileOutputStream(photoFile)
                                    fos.write(data)
                                    fos.flush()
                                    fos.close()
                                    sendEvent("mediaImported", mapOf(
                                        "fileName" to photoFile.name,
                                        "filePath" to photoFile.absolutePath,
                                        "fileType" to 2,
                                        "duration" to 0
                                    ))
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                }
                            }
                        }
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("PHOTO_ERROR", e.localizedMessage, null)
                }
            }

            "toggleRecording" -> {
                val start = call.argument<Boolean>("start") ?: true
                val cmdByte = if (start) 0x02 else 0x03
                try {
                    LargeDataHandler.getInstance().glassesControl(byteArrayOf(0x02, 0x01, cmdByte.toByte())) { _, _ -> }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("RECORD_ERROR", e.localizedMessage, null)
                }
            }

            "toggleVoiceRecording" -> {
                val start = call.argument<Boolean>("start") ?: true
                val cmdByte = if (start) 0x08 else 0x0c
                try {
                    LargeDataHandler.getInstance().glassesControl(byteArrayOf(0x02, 0x01, cmdByte.toByte())) { _, _ -> }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("VOICE_ERROR", e.localizedMessage, null)
                }
            }

            "importAlbum" -> {
                try {
                    val app = (context?.applicationContext as? android.app.Application)
                        ?: (activity?.applicationContext as? android.app.Application)
                    if (app != null) {
                        val albumDir = File(app.getExternalFilesDir(""), "DCIM_1")
                        if (!albumDir.exists()) albumDir.mkdirs()
                        val glassesControl = GlassesControl.getInstance(app)
                        glassesControl?.initGlasses(albumDir.absolutePath)
                        glassesControl?.setWifiDownloadListener(object : GlassesControl.WifiFilesDownloadListener {
                            override fun onGlassesControlSuccess() {
                                sendEvent("importProgress", mapOf("status" to "started"))
                            }
                            override fun onGlassesFail(errorCode: Int) {
                                sendEvent("importProgress", mapOf("status" to "fail", "code" to errorCode))
                            }
                            override fun wifiSpeed(wifiSpeed: String) {}
                            override fun fileProgress(fileName: String, progress: Int) {
                                sendEvent("importProgress", mapOf("status" to "downloading", "file" to fileName, "progress" to progress))
                            }
                            override fun fileWasDownloadSuccessfully(entity: GlassAlbumEntity) {
                                sendEvent("mediaImported", mapOf(
                                    "fileName" to entity.fileName,
                                    "filePath" to entity.filePath,
                                    "fileType" to entity.fileType,
                                    "duration" to entity.videoLength
                                ))
                            }
                            override fun fileCount(index: Int, total: Int) {}
                            override fun fileDownloadComplete() {
                                sendEvent("importProgress", mapOf("status" to "complete"))
                            }
                            override fun fileDownloadError(fileType: Int, errorType: Int) {}
                            override fun eisEnd(fileName: String, filePath: String) {}
                            override fun eisError(fileName: String, sourcePath: String, errorInfo: String) {}
                            override fun recordingToPcm(fileName: String, filePath: String, duration: Int) {}
                            override fun recordingToPcmError(fileName: String, errorInfo: String) {}
                        })
                        glassesControl?.importAlbum()
                        result.success(true)
                    } else {
                        result.error("APP_NULL", "Application instance unavailable", null)
                    }
                } catch (e: Exception) {
                    result.error("IMPORT_ERROR", e.localizedMessage, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun sendEvent(eventName: String, data: Map<String, Any?>) {
        val payload = HashMap<String, Any?>()
        payload["event"] = eventName
        payload.putAll(data)
        mainHandler.post {
            eventSink?.success(payload)
        }
    }
}
