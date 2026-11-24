package com.spokenodyssey.app

import android.annotation.SuppressLint
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.util.Log
import com.oudmon.ble.base.bluetooth.BleOperateManager
import com.oudmon.ble.base.bluetooth.DeviceManager
import com.oudmon.ble.base.communication.LargeDataHandler
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Audio (speaker / microphone) link to the glasses.
 *
 * The app talks to the glasses over Bluetooth Low Energy, which only carries commands. Sound
 * needs the glasses' separate *classic* Bluetooth side (A2DP for media, HFP for calls), which the
 * phone must pair with. Flow, following the vendor sample (btnBt + BluetoothReceiver):
 *  1. `syncClassicBluetooth` asks the glasses for their classic Bluetooth address/name.
 *  2. `openBT` turns the glasses' classic Bluetooth on.
 *  3. Classic discovery finds that address, then `createBondBluetoothJieLi` pairs it
 *     (Android shows its normal "Pair?" dialog).
 *  4. Once paired, Android routes media/call audio to the glasses over A2DP/HFP.
 */
@SuppressLint("MissingPermission")
class GlassesAudioLink(
    private val context: Context,
    private val handler: Handler,
    private val emit: (Map<String, Any?>) -> Unit,
) {
    private companion object { const val TAG = "GlassesAudio" }

    private val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var a2dp: BluetoothA2dp? = null
    private var headset: BluetoothHeadset? = null
    private var classicAddress: String? = null
    private var classicName: String? = null
    private var pairing = false
    private var receiver: BroadcastReceiver? = null
    private val discoveryTimeout = Runnable { onDiscoveryTimeout() }

    fun start() {
        val a = adapter ?: return
        try {
            a.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    when (profile) {
                        BluetoothProfile.A2DP -> a2dp = proxy as BluetoothA2dp
                        BluetoothProfile.HEADSET -> headset = proxy as BluetoothHeadset
                    }
                }
                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.A2DP) a2dp = null
                    if (profile == BluetoothProfile.HEADSET) headset = null
                }
            }, BluetoothProfile.A2DP)
            a.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.HEADSET) headset = proxy as BluetoothHeadset
                }
                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.HEADSET) headset = null
                }
            }, BluetoothProfile.HEADSET)
        } catch (t: Throwable) {
            t.printStackTrace()
        }
        registerReceiver()
    }

    fun stop() {
        handler.removeCallbacks(discoveryTimeout)
        receiver?.let { try { context.unregisterReceiver(it) } catch (_: Throwable) {} }
        receiver = null
        try {
            a2dp?.let { adapter?.closeProfileProxy(BluetoothProfile.A2DP, it) }
            headset?.let { adapter?.closeProfileProxy(BluetoothProfile.HEADSET, it) }
        } catch (_: Throwable) {}
    }

    /** Called when the BLE link drops. */
    fun reset() {
        classicAddress = null
        classicName = null
        cancelPairing()
    }

    // ───────────────────────────── Status ─────────────────────────────

    /** Reads the glasses' classic address (if needed) and reports the current audio state. */
    fun refreshStatus(done: (Map<String, Any?>) -> Unit) {
        fetchClassicInfo { status().also(done) }
    }

    fun status(): Map<String, Any?> {
        val device = targetDevice()
        val bonded = device?.bondState == BluetoothDevice.BOND_BONDED
        val connected = device != null && isAudioConnected(device)
        val state = when {
            pairing -> "pairing"
            connected -> "connected"
            bonded -> "paired"
            else -> "notPaired"
        }
        return mapOf(
            "state" to state,
            "address" to (device?.address ?: classicAddress ?: ""),
            "name" to (device?.name ?: classicName ?: ""),
            "media" to (device != null && isConnected(a2dp, device)),
            "calls" to (device != null && isConnected(headset, device)),
        )
    }

    private fun isConnected(proxy: BluetoothProfile?, device: BluetoothDevice): Boolean = try {
        proxy?.getConnectionState(device) == BluetoothProfile.STATE_CONNECTED
    } catch (_: Throwable) { false }

    private fun isAudioConnected(device: BluetoothDevice) =
        isConnected(a2dp, device) || isConnected(headset, device)

    /** The glasses' classic device: by reported address, else a bonded device with their name. */
    private fun targetDevice(): BluetoothDevice? {
        val a = adapter ?: return null
        val addr = classicAddress
        val bonded = try { a.bondedDevices } catch (_: Throwable) { null } ?: emptySet()
        if (!addr.isNullOrEmpty()) {
            bonded.firstOrNull { it.address.equals(addr, ignoreCase = true) }?.let { return it }
            return try { a.getRemoteDevice(addr.uppercase(Locale.US)) } catch (_: Throwable) { null }
        }
        val names = listOfNotNull(classicName, DeviceManager.getInstance().deviceName)
            .filter { it.isNotBlank() }
        return bonded.firstOrNull { d -> names.any { n -> d.name?.equals(n, ignoreCase = true) == true } }
    }

    private fun fetchClassicInfo(done: () -> Unit) {
        if (!classicAddress.isNullOrEmpty()) {
            done()
            return
        }
        Log.i(TAG, "requesting classic Bluetooth info (bleConnected=${BleOperateManager.getInstance().isConnected})")
        val finished = AtomicBoolean(false)
        val timeout = Runnable { if (finished.compareAndSet(false, true)) done() }
        handler.postDelayed(timeout, 3000)
        try {
            LargeDataHandler.getInstance().syncClassicBluetooth { _, rsp ->
                Log.i(TAG, "classic info: address=${rsp?.btAddress} name=${rsp?.btName}")
                if (rsp != null) {
                    rsp.btAddress?.takeIf { it.length >= 17 && it != "00:00:00:00:00:00" }?.let {
                        classicAddress = it.uppercase(Locale.US)
                    }
                    rsp.btName?.trim()?.trimEnd('\u0000')?.takeIf { it.isNotEmpty() }?.let { classicName = it }
                }
                if (finished.compareAndSet(false, true)) {
                    handler.removeCallbacks(timeout)
                    handler.post(done)
                }
            }
        } catch (t: Throwable) {
            t.printStackTrace()
            if (finished.compareAndSet(false, true)) {
                handler.removeCallbacks(timeout)
                done()
            }
        }
    }

    // ───────────────────────────── Pairing ─────────────────────────────

    /** Starts pairing / reconnecting the glasses' audio. Progress arrives as audioState events. */
    fun connect(done: (Map<String, Any?>) -> Unit) {
        if (adapter?.isEnabled != true) {
            done(mapOf("state" to "failed", "reason" to "bluetoothOff"))
            return
        }
        fetchClassicInfo {
            val device = targetDevice()
            when {
                device != null && isAudioConnected(device) -> {
                    done(status())
                }
                device != null && device.bondState == BluetoothDevice.BOND_BONDED -> {
                    // Already paired: wake the glasses' classic side and ask the profiles to connect.
                    openClassicBluetooth()
                    handler.postDelayed({ connectProfiles(device) }, 1200)
                    emitState("connecting")
                    done(mapOf("state" to "connecting"))
                    handler.postDelayed({ if (!isAudioConnected(device)) emitState(status()["state"] as String) }, 12000)
                }
                else -> {
                    startPairing()
                    done(mapOf("state" to "pairing"))
                }
            }
        }
    }

    private fun openClassicBluetooth() {
        try { LargeDataHandler.getInstance().openBT() } catch (t: Throwable) { t.printStackTrace() }
    }

    private fun startPairing() {
        pairing = true
        emitState("pairing")
        openClassicBluetooth()
        handler.postDelayed({
            try {
                if (adapter?.isDiscovering == true) adapter.cancelDiscovery()
                BleOperateManager.getInstance().classicBluetoothStartScan()
            } catch (t: Throwable) {
                t.printStackTrace()
                try { adapter?.startDiscovery() } catch (_: Throwable) {}
            }
            handler.removeCallbacks(discoveryTimeout)
            handler.postDelayed(discoveryTimeout, 15000)
        }, 1500)
    }

    private fun onDiscoveryTimeout() {
        if (!pairing) return
        try { BleOperateManager.getInstance().classicBluetoothStopScan() } catch (_: Throwable) {}
        // Not seen during discovery: try pairing the reported address directly.
        val addr = classicAddress
        if (!addr.isNullOrEmpty()) {
            val device = try { adapter?.getRemoteDevice(addr) } catch (_: Throwable) { null }
            if (device != null && device.bondState != BluetoothDevice.BOND_BONDED) {
                bond(device)
                return
            }
        }
        pairing = false
        emitState("failed", "notFound")
    }

    private fun cancelPairing() {
        if (!pairing) return
        pairing = false
        handler.removeCallbacks(discoveryTimeout)
        try { BleOperateManager.getInstance().classicBluetoothStopScan() } catch (_: Throwable) {}
    }

    private fun matchesTarget(device: BluetoothDevice): Boolean {
        val addr = classicAddress
        if (!addr.isNullOrEmpty()) return device.address.equals(addr, ignoreCase = true)
        val name = try { device.name } catch (_: Throwable) { null } ?: return false
        val names = listOfNotNull(classicName, DeviceManager.getInstance().deviceName).filter { it.isNotBlank() }
        return names.any { it.equals(name, ignoreCase = true) }
    }

    private fun bond(device: BluetoothDevice) {
        handler.removeCallbacks(discoveryTimeout)
        try { if (adapter?.isDiscovering == true) adapter.cancelDiscovery() } catch (_: Throwable) {}
        try {
            BleOperateManager.getInstance().createBondBluetoothJieLi(device)
        } catch (t: Throwable) {
            t.printStackTrace()
            try { device.createBond() } catch (_: Throwable) {}
        }
        // If no bonding starts (e.g. the dialog was dismissed instantly), report failure.
        handler.postDelayed({
            if (pairing && device.bondState == BluetoothDevice.BOND_NONE) {
                pairing = false
                emitState("failed", "pairingRejected")
            }
        }, 30000)
    }

    /** Asks A2DP/HFP to connect. These calls are hidden APIs; failures are expected on some phones. */
    private fun connectProfiles(device: BluetoothDevice) {
        for (proxy in listOfNotNull<BluetoothProfile>(a2dp, headset)) {
            try {
                proxy.javaClass.getMethod("connect", BluetoothDevice::class.java).invoke(proxy, device)
            } catch (_: Throwable) {}
        }
    }

    // ───────────────────────────── System events ─────────────────────────────

    private fun registerReceiver() {
        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                } else {
                    @Suppress("DEPRECATION") intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
                when (intent.action) {
                    BluetoothDevice.ACTION_FOUND -> {
                        if (pairing) Log.i(TAG, "found ${device?.address} ${try { device?.name } catch (_: Throwable) { null }}")
                        if (pairing && device != null && matchesTarget(device)) {
                            if (classicAddress.isNullOrEmpty()) classicAddress = device.address
                            bond(device)
                        }
                    }
                    BluetoothDevice.ACTION_BOND_STATE_CHANGED -> {
                        if (device == null || !matchesTarget(device)) return
                        val now = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.BOND_NONE)
                        val before = intent.getIntExtra(BluetoothDevice.EXTRA_PREVIOUS_BOND_STATE, BluetoothDevice.BOND_NONE)
                        when (now) {
                            BluetoothDevice.BOND_BONDED -> {
                                pairing = false
                                emitState("paired")
                                handler.postDelayed({ connectProfiles(device) }, 1500)
                            }
                            BluetoothDevice.BOND_NONE -> if (before == BluetoothDevice.BOND_BONDING && pairing) {
                                pairing = false
                                emitState("failed", "pairingRejected")
                            }
                        }
                    }
                    BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED,
                    BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED -> {
                        if (device != null && matchesTarget(device)) {
                            handler.postDelayed({ emit(HashMap(status()).apply { put("event", "audioState") }) }, 300)
                        }
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
            addAction(BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)
            addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
    }

    private fun emitState(state: String, reason: String? = null) {
        Log.i(TAG, "audio state=$state reason=$reason target=$classicAddress")
        val payload = HashMap(status())
        payload["event"] = "audioState"
        payload["state"] = state
        if (reason != null) payload["reason"] = reason
        emit(payload)
    }
}
