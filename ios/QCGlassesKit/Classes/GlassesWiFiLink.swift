import CoreBluetooth
import Foundation
import NetworkExtension

#if !targetEnvironment(simulator) && canImport(QCSDK)
import QCSDK
#endif

/// Puts the iPhone on the glasses' Wi‑Fi hotspot for a media transfer.
///
/// Same flow as the official HeyCyan app's "Compatibility transfer" (hotspot) mode:
/// 1. Ask the glasses to turn on their **hotspot**: control command `02 01 04 02`
///    (`GlassesHotspot`). The QCSDK's `openWifi` sends `02 01 04`, which starts Wi‑Fi Direct
///    instead; iOS can't join that, so the network never appears ("Unable to join the network").
/// 2. Network name + password: from the hotspot reply, else saved from an earlier import, else
///    learned once through the QCSDK (`openWifi`, whose reply carries them), after which that
///    Wi‑Fi Direct session is ended and the hotspot is requested.
/// 3. The caller starts the transfer heartbeat (`step == .waitingForHotspot`), then the hotspot
///    gets time to come up.
/// 4. Join with `NEHotspotConfiguration` and confirm the phone really got an address on that
///    network. Not yet → wait and apply the same configuration again (no new "Join" prompt).
/// 5. The glasses' HTTP server is the hotspot's gateway (`x.x.x.1`), like the official app's
///    "IP returned by the system". (The QCSDK's `getDeviceWifiIP` decodes the Bluetooth reply one
///    byte off, e.g. `c0 a8 1f 01` → "3.192.168.31", so it isn't used.)
///
/// Every step is logged as `[GlassesImport] …`.
public final class GlassesWiFiLink {

    public enum Step {
        case openingWiFi
        /// The glasses accepted; their hotspot is starting. Start the heartbeat now.
        case waitingForHotspot
        /// iOS can't switch from the phone's current Wi‑Fi to the glasses (see `couldNotLeaveWiFi`).
        /// Ask the user to disconnect (Control Center → tap Wi‑Fi); the import continues by itself
        /// once they do. Sent again every few seconds while waiting (keeps the UI watchdog alive).
        case needsWiFiDisconnect
        /// The user disconnected; connecting to the glasses now.
        case wifiDisconnected
        case joining(attempt: Int, of: Int)
    }

    public enum Outcome {
        /// `host` is the glasses' address on their hotspot (HTTP server for media).
        case joined(ssid: String, host: String)
        /// The user tapped "Cancel" on the system "Join Wi‑Fi network" prompt.
        case declined
        /// The glasses refused to open Wi‑Fi because they are busy (QCOperatorDeviceMode value).
        case busy(mode: Int)
        /// The glasses didn't answer the "open Wi‑Fi" command.
        case noResponse
        /// The phone couldn't get onto the glasses' network. `detail` says what was observed.
        case joinFailed(detail: String)
        /// Same, while the phone was on another Wi‑Fi network. Measured on an iPhone X / iOS 16:
        /// from a 5 GHz network iOS refuses the switch instantly (wifid `_performAssociation …
        /// error:0x3`, "Unable to join the network") even though the hotspot is up; from no Wi‑Fi
        /// (Control Center → tap Wi‑Fi) or a 2.4 GHz network the same join works. Apps can't
        /// disconnect the phone, so the user is asked to.
        case couldNotLeaveWiFi(detail: String)
        /// Glasses SDK not available (Simulator).
        case unsupported
    }

    /// Address the glasses use on their own hotspot (also hard-coded in the QCSDK, and what the
    /// glasses report over Bluetooth: c0 a8 1f 01).
    public static let defaultHost = "192.168.31.1"

    private static let transferMode = 0x04
    private static let transferStopMode = 0x09
    /// Time the glasses need to bring their access point up after accepting the command.
    ///
    /// Every `NEHotspotConfiguration.apply` shows the system "Join Wi‑Fi network?" prompt again,
    /// and an apply made before the hotspot broadcasts ends in "Unable to join the network". So the
    /// first apply must wait until the hotspot is up. The glasses send no "hotspot ready" signal
    /// (checked in the iOS + Android SDKs and the official app), so this is a fixed wait.
    /// Measured (iPhone log, scan results): the hotspot was not visible 12–16 s after the glasses'
    /// reply and was visible from ~17 s on (once by 11 s). 20 s plus the user's tap on "Join"
    /// covers that.
    private static let warmUp: TimeInterval = 20
    /// Each attempt is one system "Join" prompt. Normally one is enough; the others cover a
    /// hotspot that wasn't up yet and the retry after the user disconnected from their Wi‑Fi.
    private static let maxJoinAttempts = 3
    /// How long to wait for the user to disconnect from their Wi‑Fi.
    private static let disconnectTimeout: TimeInterval = 120
    /// The phone must stay off its Wi‑Fi this long to count as disconnected by the user.
    /// After a refused switch iOS drops the home network by itself for 1–4 s (measured) and
    /// rejoins it, so until the phone has been seen back on it, a longer wait applies.
    private static let disconnectSettle: TimeInterval = 1.5
    private static let disconnectSettleAfterRefusal: TimeInterval = 6
    /// How often the "please disconnect" step is repeated while waiting.
    private static let disconnectReminder: TimeInterval = 10
    /// Subnets (x.x.x) of the user's networks from which iOS refused to switch to the glasses.
    /// Next time on such a network the user is asked to disconnect right away, while the hotspot
    /// starts, instead of after a failed join.
    private static let blockedSubnetsKey = "GlassesWiFiSwitchBlockedSubnets"
    /// Wait before applying again. After a failed join the hotspot can drop for a few seconds,
    /// so retrying quickly fails again ("not found").
    private static let retryDelay: TimeInterval = 8
    /// After `apply` returns, how long iOS may take to report the glasses' SSID. `apply` returns
    /// (without an error) when iOS has either joined or given up. Switching away from another
    /// network can take well over 5 s, and declaring failure too early used to blacklist the
    /// phone's own network as "can't switch" (see `join`), forcing the manual disconnect flow
    /// on every later import — so this window is generous.
    private static let associationTimeout: TimeInterval = 12
    /// Once on the glasses' network, how long DHCP may take to give the phone an address.
    private static let verifyTimeout: TimeInterval = 20
    private static let verifyInterval: TimeInterval = 1
    /// Pause after ending a transfer before the glasses accept the next mode command.
    private static let modeSwitchDelay: TimeInterval = 2

    /// SSID of the network this class configured (removed again by `leave()`).
    public private(set) static var currentSSID: String?

    private static var generation = 0
    /// The phone's Wi‑Fi address before joining (to tell the glasses' network from the home one).
    private static var addressBeforeJoin: String?

    /// Turns on the glasses' hotspot and joins it. Callbacks run on the main queue.
    public static func connect(peripheral: CBPeripheral?, step: @escaping (Step) -> Void,
                               completion: @escaping (Outcome) -> Void) {
        generation += 1
        let token = generation
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        guard let peripheral = peripheral else {
            DispatchQueue.main.async { completion(.noResponse) }
            return
        }
        let finish = Once<Outcome>(timeout: 300, fallback: .joinFailed(detail: "timed out")) { outcome in
            guard token == generation else { return }
            GlassesLog.log("Wi-Fi link result: \(describe(outcome))")
            switch outcome {
            case .joinFailed, .couldNotLeaveWiFi:
                // Maybe the saved name/password are stale: learn them again next time.
                GlassesHotspot.forgetCredentials(for: peripheral)
            default:
                break
            }
            completion(outcome)
        }
        addressBeforeJoin = wifiIPv4Address()
        GlassesLog.log("step 1: asking the glasses to turn on their hotspot (phone Wi-Fi IP now: \(addressBeforeJoin ?? "none"))")
        step(.openingWiFi)

        requestHotspot(peripheral: peripheral, allowRecovery: true, token: token) { result in
            switch result {
            case .failure(let outcome):
                finish(outcome)
            case .ready(let fromReply):
                if let credentials = fromReply ?? GlassesHotspot.savedCredentials(for: peripheral) {
                    GlassesHotspot.save(credentials, for: peripheral)
                    startJoin(credentials, token: token, step: step, completion: { finish($0) })
                    return
                }
                learnCredentials(peripheral: peripheral, token: token) { learned in
                    switch learned {
                    case .failure(let outcome):
                        finish(outcome)
                    case .ready(let credentials):
                        guard let credentials = credentials else { return finish(.noResponse) }
                        startJoin(credentials, token: token, step: step, completion: { finish($0) })
                    }
                }
            }
        }
        #else
        DispatchQueue.main.async { completion(.unsupported) }
        #endif
    }

    /// Stops any connection attempt in progress.
    public static func cancel() {
        generation += 1
        GlassesNotifyTap.stop()
    }

    /// Forgets the glasses' network so the iPhone returns to its usual Wi‑Fi and internet.
    public static func leave() {
        cancel()
        guard let ssid = currentSSID else { return }
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        GlassesLog.log("left the glasses' Wi-Fi \"\(ssid)\"")
        currentSSID = nil
    }

    // MARK: - 1. Hotspot on

    private enum HotspotResult {
        /// Hotspot is on; credentials when the glasses sent them.
        case ready(GlassesHotspot.Credentials?)
        case failure(Outcome)
    }

    private static func requestHotspot(peripheral: CBPeripheral, allowRecovery: Bool, token: Int,
                                       completion: @escaping (HotspotResult) -> Void) {
        GlassesHotspot.request(peripheral: peripheral) { reply in
            guard token == generation else { return }
            switch reply {
            case .accepted(let ssid, let password):
                GlassesLog.log("glasses accepted hotspot mode\(ssid.map { ": ssid=\"\($0)\"" } ?? "")")
                if let ssid = ssid, !ssid.isEmpty, let password = password {
                    completion(.ready(GlassesHotspot.Credentials(ssid: ssid, password: password)))
                } else {
                    completion(.ready(nil))
                }
            case .noReply:
                // The command may still have worked; the join below will tell.
                GlassesLog.log("no reply to the hotspot command; continuing")
                completion(.ready(nil))
            case .busy(let mode):
                GlassesLog.log("glasses refused hotspot mode, busy in mode \(mode)")
                if mode == transferMode && allowRecovery {
                    // Still in an earlier transfer (e.g. Wi‑Fi Direct): end it and ask again.
                    endTransfer {
                        requestHotspot(peripheral: peripheral, allowRecovery: false, token: token, completion: completion)
                    }
                } else {
                    completion(.failure(mode < 0 ? .noResponse : .busy(mode: mode)))
                }
            }
        }
    }

    /// Learns the hotspot name/password once through the QCSDK (its `openWifi` reply carries
    /// them), then ends that Wi‑Fi Direct session and turns the hotspot on.
    private static func learnCredentials(peripheral: CBPeripheral, token: Int,
                                         completion: @escaping (HotspotResult) -> Void) {
        GlassesLog.log("no saved hotspot name/password yet; reading them through the SDK")
        endTransfer {
            guard token == generation else { return }
            openWiFi(allowTransferRecovery: true) { result in
                guard token == generation else { return }
                switch result {
                case .failure(let outcome):
                    completion(.failure(outcome))
                case .success(let (ssid, passphrase)):
                    let credentials = GlassesHotspot.Credentials(ssid: ssid, password: passphrase)
                    GlassesHotspot.save(credentials, for: peripheral)
                    GlassesLog.log("learned ssid=\"\(ssid)\" password=\(passphrase.count) chars; switching to hotspot")
                    endTransfer {
                        requestHotspot(peripheral: peripheral, allowRecovery: true, token: token) { hotspot in
                            switch hotspot {
                            case .failure(let outcome): completion(.failure(outcome))
                            case .ready(let fromReply): completion(.ready(fromReply ?? credentials))
                            }
                        }
                    }
                }
            }
        }
    }

    private static func endTransfer(_ then: @escaping () -> Void) {
        QCGlassesBridge.shared.setMode(transferStopMode) { _, _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + modeSwitchDelay, execute: then)
        }
    }

    private enum OpenResult {
        case success((String, String))
        case failure(Outcome)
    }

    /// QCSDK `openWifi(.transfer)`: only used to read the network name and password.
    private static func openWiFi(allowTransferRecovery: Bool, completion: @escaping (OpenResult) -> Void) {
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        let reply = Once<OpenResult>(timeout: 15, fallback: .failure(.noResponse), completion)
        QCSDKCmdCreator.openWifi(with: .transfer, success: { ssid, passphrase in
            guard !ssid.isEmpty else {
                GlassesLog.log("glasses accepted but sent no SSID")
                reply(.failure(.noResponse))
                return
            }
            reply(.success((ssid, passphrase)))
        }, fail: { busyMode in
            GlassesLog.log("glasses refused to open Wi-Fi, busy in mode \(busyMode)")
            if busyMode == transferMode && allowTransferRecovery {
                GlassesLog.log("ending the previous transfer and retrying")
                endTransfer {
                    openWiFi(allowTransferRecovery: false) { reply($0) }
                }
            } else {
                reply(.failure(.busy(mode: busyMode)))
            }
        })
        #else
        completion(.failure(.unsupported))
        #endif
    }

    // MARK: - 2/3. Join and confirm

    private static func startJoin(_ credentials: GlassesHotspot.Credentials, token: Int,
                                  step: @escaping (Step) -> Void, completion: @escaping (Outcome) -> Void) {
        guard token == generation else { return }
        currentSSID = credentials.ssid
        step(.waitingForHotspot)
        let hotspotReady = Date().addingTimeInterval(warmUp)
        let firstJoin = {
            join(ssid: credentials.ssid, passphrase: credentials.password, attempt: 1, lastError: nil,
                 token: token, step: step, completion: completion)
        }
        if let address = homeWiFiAddress(), isSwitchBlocked(from: address) {
            // This network refused the switch before: ask now, while the hotspot starts.
            GlassesLog.log("step 2: the phone's Wi-Fi (\(subnet(address)).x) blocked the switch before; " +
                           "asking the user to disconnect while the hotspot starts")
            waitForWiFiDisconnect(token: token, step: step) { disconnected in
                guard disconnected else {
                    return completion(.couldNotLeaveWiFi(detail: "phone stayed on its Wi-Fi (IP \(address))"))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0, hotspotReady.timeIntervalSinceNow)) {
                    firstJoin()
                }
            }
        } else {
            GlassesLog.log("step 2: waiting \(Int(warmUp)) s for the hotspot \"\(credentials.ssid)\" to start")
            DispatchQueue.main.asyncAfter(deadline: .now() + warmUp) { firstJoin() }
        }
    }

    // MARK: - Leaving the phone's Wi‑Fi

    /// The phone's address on a Wi‑Fi network other than the glasses', if it's on one.
    private static func homeWiFiAddress() -> String? {
        guard let address = wifiIPv4Address(), isUsableIPv4(address), !address.hasPrefix("169.254."),
              !isOnSubnet(address, of: defaultHost) else { return nil }
        return address
    }

    private static func isSwitchBlocked(from address: String) -> Bool {
        (UserDefaults.standard.stringArray(forKey: blockedSubnetsKey) ?? []).contains(subnet(address))
    }

    private static func rememberSwitchBlocked(from address: String) {
        var subnets = UserDefaults.standard.stringArray(forKey: blockedSubnetsKey) ?? []
        guard !subnets.contains(subnet(address)) else { return }
        subnets.append(subnet(address))
        UserDefaults.standard.set(subnets, forKey: blockedSubnetsKey)
        GlassesLog.log("remembered: iOS can't switch from Wi-Fi \(subnet(address)).x to the glasses")
    }

    /// A direct join from this network worked, so it does not block the switch after all.
    /// Clears an earlier record (which may have come from one transient failure, e.g. the
    /// hotspot not being up yet) so it can't force the manual disconnect flow forever.
    private static func forgetSwitchBlocked(from address: String) {
        var subnets = UserDefaults.standard.stringArray(forKey: blockedSubnetsKey) ?? []
        guard subnets.contains(subnet(address)) else { return }
        subnets.removeAll { $0 == subnet(address) }
        UserDefaults.standard.set(subnets, forKey: blockedSubnetsKey)
        GlassesLog.log("forgot the Wi-Fi switch block for \(subnet(address)).x: a direct join worked")
    }

    /// Asks the user to disconnect from their Wi‑Fi (`.needsWiFiDisconnect`) and waits until the
    /// phone has stayed off it for `disconnectSettle` seconds. Completion `false` on timeout.
    private static func waitForWiFiDisconnect(token: Int, step: @escaping (Step) -> Void,
                                              completion: @escaping (_ disconnected: Bool) -> Void) {
        let deadline = Date().addingTimeInterval(disconnectTimeout)
        var lastReminder = Date.distantPast
        var offSince: Date?
        // Off the Wi‑Fi right now may just be iOS rejoining it after a refused switch.
        var seenOnWiFi = homeWiFiAddress() != nil
        func poll() {
            guard token == generation else { return }
            let now = Date()
            if homeWiFiAddress() == nil {
                let since = offSince ?? now
                offSince = since
                let settle = seenOnWiFi ? disconnectSettle : disconnectSettleAfterRefusal
                if now.timeIntervalSince(since) >= settle {
                    GlassesLog.log("phone is off its Wi-Fi; connecting to the glasses")
                    step(.wifiDisconnected)
                    return completion(true)
                }
            } else {
                offSince = nil
                seenOnWiFi = true
                if now >= deadline {
                    GlassesLog.log("phone stayed on its Wi-Fi for \(Int(disconnectTimeout)) s")
                    return completion(false)
                }
                if now.timeIntervalSince(lastReminder) >= disconnectReminder {
                    lastReminder = now
                    step(.needsWiFiDisconnect)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { poll() }
        }
        GlassesLog.log("waiting for the user to disconnect from their Wi-Fi (Control Center → Wi-Fi)")
        poll()
    }

    private static func join(ssid: String, passphrase: String, attempt: Int, lastError: String?,
                             token: Int, step: @escaping (Step) -> Void, completion: @escaping (Outcome) -> Void) {
        guard token == generation else { return }
        step(.joining(attempt: attempt, of: maxJoinAttempts))
        GlassesLog.log("step 3: joining \"\(ssid)\" (attempt \(attempt)/\(maxJoinAttempts))")
        // Remove any leftover configuration for this SSID before applying: a stale one
        // can make `apply` report success without iOS actually associating again.
        NEHotspotConfigurationManager.shared.getConfiguredSSIDs { configuredSSIDs in
            DispatchQueue.main.async {
                guard token == generation else { return }
                if configuredSSIDs.contains(ssid) {
                    GlassesLog.log("removing leftover Wi-Fi configuration for \"\(ssid)\" before joining")
                    NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        applyJoin(ssid: ssid, passphrase: passphrase, attempt: attempt,
                                  lastError: lastError, token: token, step: step, completion: completion)
                    }
                } else {
                    applyJoin(ssid: ssid, passphrase: passphrase, attempt: attempt,
                              lastError: lastError, token: token, step: step, completion: completion)
                }
            }
        }
    }

    /// Builds the hotspot configuration and applies it (the second half of `join`).
    private static func applyJoin(ssid: String, passphrase: String, attempt: Int, lastError: String?,
                                  token: Int, step: @escaping (Step) -> Void, completion: @escaping (Outcome) -> Void) {
        guard token == generation else { return }
        let configuration = passphrase.isEmpty
            ? NEHotspotConfiguration(ssid: ssid)
            : NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
        // Kept until `leave()`: the phone stays on the glasses' network (it has no internet)
        // during the import, and re-applying it on a retry doesn't ask the user again.
        configuration.joinOnce = false

        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            DispatchQueue.main.async {
                guard token == generation else { return }
                var applyError = lastError
                if let error = error as NSError? {
                    applyError = "\(error.domain) \(error.code): \(error.localizedDescription)"
                    GlassesLog.log("apply returned error: \(applyError ?? "")")
                    if error.domain == NEHotspotConfigurationErrorDomain,
                       NEHotspotConfigurationError(rawValue: error.code) == .userDenied {
                        completion(.declined)
                        return
                    }
                } else {
                    GlassesLog.log("apply accepted by iOS, checking the connection…")
                }
                // A failed attempt is only evidence that iOS refused to leave the phone's
                // Wi‑Fi when `apply` itself reported an error, or when a retry failed too.
                // An error-free `apply` whose SSID never showed up on the first attempt
                // usually just means the glasses' hotspot wasn't broadcasting yet — the
                // phone staying on its Wi‑Fi is expected then, and must not blacklist the
                // network or send the user to disconnect manually.
                let switchRefused = applyError != nil || attempt >= 2
                let retryOrFail: (String) -> Void = { state in
                    // The phone was on its own Wi‑Fi and iOS refused to switch: ask the user
                    // to disconnect, then continue by itself.
                    if attempt < maxJoinAttempts, switchRefused, let previous = addressBeforeJoin,
                       homeWiFiAddress() != nil || !isSwitchBlocked(from: previous) {
                        rememberSwitchBlocked(from: previous)
                        GlassesLog.log("iOS couldn't switch from the phone's Wi-Fi (\(state)); asking the user to disconnect")
                        waitForWiFiDisconnect(token: token, step: step) { disconnected in
                            guard disconnected else {
                                var detail = "phone \(state)"
                                if let applyError = applyError { detail += "; iOS: \(applyError)" }
                                return completion(.couldNotLeaveWiFi(detail: detail + "; phone stayed on Wi-Fi (IP \(previous))"))
                            }
                            // The hotspot can drop for a few seconds after a refused join.
                            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                                join(ssid: ssid, passphrase: passphrase, attempt: attempt + 1,
                                     lastError: applyError, token: token, step: step, completion: completion)
                            }
                        }
                        return
                    }
                    if attempt < maxJoinAttempts {
                        GlassesLog.log("not on the glasses' Wi-Fi (\(state)); retrying in \(Int(retryDelay)) s")
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            join(ssid: ssid, passphrase: passphrase, attempt: attempt + 1,
                                 lastError: applyError, token: token, step: step, completion: completion)
                        }
                    } else {
                        var detail = "phone \(state)"
                        if let applyError = applyError { detail += "; iOS: \(applyError)" }
                        if let current = homeWiFiAddress() {
                            completion(.couldNotLeaveWiFi(detail: detail + "; phone is on Wi-Fi (IP \(current))"))
                        } else {
                            completion(.joinFailed(detail: detail))
                        }
                    }
                }
                // `apply` also returns without an error when iOS couldn't find the network (it then
                // shows "Unable to join the network"). Check right away whether iOS is on it, so a
                // retry doesn't wait for the DHCP timeout.
                waitForSSID(ssid, deadline: Date().addingTimeInterval(associationTimeout), token: token) { associated in
                    guard token == generation else { return }
                    guard associated else {
                        retryOrFail("iOS couldn't join \"\(ssid)\" — hotspot not up yet")
                        return
                    }
                    // On the network: wait for an address (the SSID alone isn't enough).
                    verify(ssid: ssid, deadline: Date().addingTimeInterval(verifyTimeout), token: token) { address, state in
                        guard token == generation else { return }
                        if let address = address {
                            // A direct join from the phone's previous network worked, so
                            // that network does not block the switch after all.
                            if let previous = addressBeforeJoin {
                                forgetSwitchBlocked(from: previous)
                            }
                            // The glasses are the hotspot's gateway (x.x.x.1).
                            let host = subnet(address) + ".1"
                            GlassesLog.log("joined: \(state) → glasses at \(host)")
                            completion(.joined(ssid: ssid, host: host))
                        } else {
                            retryOrFail(state)
                        }
                    }
                }
            }
        }
    }

    /// Polls until iOS reports `ssid` as the current network or the deadline passes.
    private static func waitForSSID(_ ssid: String, deadline: Date, token: Int,
                                    completion: @escaping (_ associated: Bool) -> Void) {
        guard token == generation else { return }
        NEHotspotNetwork.fetchCurrent { network in
            DispatchQueue.main.async {
                guard token == generation else { return }
                let address = wifiIPv4Address()
                let newAddressOnGlassesSubnet = address.map {
                    isOnSubnet($0, of: defaultHost) && $0 != addressBeforeJoin
                } ?? false
                if network?.ssid == ssid || newAddressOnGlassesSubnet {
                    completion(true)
                } else if Date() >= deadline {
                    completion(false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        waitForSSID(ssid, deadline: deadline, token: token, completion: completion)
                    }
                }
            }
        }
    }

    /// Polls until the phone has an address on the glasses' network or the deadline passes.
    /// Reports that address (nil when not joined) and a description of what the phone is on.
    ///
    /// The SSID alone isn't enough: iOS reports it before DHCP finishes, and requests sent then
    /// fail. Joined = an address on the glasses' subnet (192.168.31.x) while iOS doesn't report
    /// another network, or iOS reports the glasses' SSID and the phone got a new address.
    private static func verify(ssid: String, deadline: Date, token: Int,
                               completion: @escaping (_ address: String?, _ state: String) -> Void) {
        guard token == generation else { return }
        networkState(ssid: ssid) { address, state in
            if address != nil || Date() >= deadline {
                completion(address, state)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + verifyInterval) {
                    verify(ssid: ssid, deadline: deadline, token: token, completion: completion)
                }
            }
        }
    }

    private static func networkState(ssid: String, completion: @escaping (_ address: String?, _ state: String) -> Void) {
        let address = wifiIPv4Address()
        NEHotspotNetwork.fetchCurrent { network in
            DispatchQueue.main.async {
                let current = network?.ssid
                let usable = address.map { isUsableIPv4($0) && !$0.hasPrefix("169.254.") } ?? false
                // A home router can use the same subnet (Xiaomi routers default to 192.168.31.x),
                // so the subnet only counts when iOS isn't reporting a different network.
                let otherNetwork = current != nil && current != ssid
                let onGlassesSubnet = usable && address.map { isOnSubnet($0, of: defaultHost) } ?? false
                let newAddressOnSSID = usable && current == ssid && address != addressBeforeJoin
                let joined = (onGlassesSubnet && !otherNetwork) || newAddressOnSSID
                let state = "on Wi-Fi \"\(current ?? "unknown")\", IP \(address ?? "none")"
                completion(joined ? address : nil, state)
            }
        }
    }

    /// True when `address` is a usable address on the same /24 as the glasses (`host`).
    static func isOnSubnet(_ address: String, of host: String) -> Bool {
        address != host && !address.hasPrefix("169.254.") && subnet(address) == subnet(host)
    }

    // MARK: - Helpers

    private static func describe(_ outcome: Outcome) -> String {
        switch outcome {
        case .joined(let ssid, let host): return "joined \(ssid), glasses at \(host)"
        case .declined: return "user tapped Cancel on the Join prompt"
        case .busy(let mode): return "glasses busy (mode \(mode))"
        case .noResponse: return "glasses didn't answer the hotspot command"
        case .joinFailed(let detail): return "join failed — \(detail)"
        case .couldNotLeaveWiFi(let detail): return "couldn't switch from the phone's Wi-Fi — \(detail)"
        case .unsupported: return "unsupported (Simulator)"
        }
    }

    private static func isUsableIPv4(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ".")
        guard parts.count == 4, parts.allSatisfy({ UInt8($0) != nil }) else { return false }
        return trimmed != "0.0.0.0"
    }

    private static func subnet(_ address: String) -> String {
        address.split(separator: ".").prefix(3).joined(separator: ".")
    }

    /// IPv4 address of the Wi‑Fi interface (en0), if any.
    static func wifiIPv4Address() -> String? {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let first = pointer else { return nil }
        defer { freeifaddrs(pointer) }
        var current: UnsafeMutablePointer<ifaddrs>? = first
        while let entry = current {
            defer { current = entry.pointee.ifa_next }
            guard let addr = entry.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET),
                  String(cString: entry.pointee.ifa_name) == "en0" else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count),
                           nil, 0, NI_NUMERICHOST) == 0 {
                return String(cString: host)
            }
        }
        return nil
    }
}
