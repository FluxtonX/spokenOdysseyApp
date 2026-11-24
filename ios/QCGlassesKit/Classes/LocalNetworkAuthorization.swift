import Foundation
import Network

/// Asks iOS for Local Network access up front and reports the answer.
///
/// iOS has no API to request or read this permission directly. The standard technique is to
/// publish a Bonjour service and browse for it: publishing succeeds once access is granted, and
/// the browser reports `PolicyDenied` when it is refused. The first run shows the system
/// "Find devices on local networks" prompt inside the app.
///
/// The service types used here must be listed in Info.plist `NSBonjourServices`
/// (`_lnp._tcp`), next to `NSLocalNetworkUsageDescription`.
public final class LocalNetworkAuthorization: NSObject, NetServiceDelegate {

    public enum Status {
        case granted
        case denied
        /// The user hasn't answered the prompt in time (or it couldn't be checked).
        case undetermined
    }

    private static let serviceType = "_lnp._tcp"

    private var browser: NWBrowser?
    private var service: NetService?
    private var completion: ((Status) -> Void)?
    private var timeoutItem: DispatchWorkItem?

    /// Keeps the in-flight request alive until it reports.
    private static var active: LocalNetworkAuthorization?

    /// Calls `completion` on the main queue exactly once.
    public static func request(timeout: TimeInterval = 60, completion: @escaping (Status) -> Void) {
        DispatchQueue.main.async {
            active?.finish(.undetermined)
            let request = LocalNetworkAuthorization()
            active = request
            request.start(timeout: timeout, completion: completion)
        }
    }

    private func start(timeout: TimeInterval, completion: @escaping (Status) -> Void) {
        self.completion = completion

        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: Self.serviceType, domain: nil), using: parameters)
        browser.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed(let error):
                if case .dns(let code) = error, code == -65570 {
                    self?.finish(.denied)
                } else {
                    self?.finish(.undetermined)
                }
            case .waiting(let error):
                if case .dns(let code) = error, code == -65570 { // kDNSServiceErr_PolicyDenied
                    self?.finish(.denied)
                }
            default:
                break
            }
        }
        self.browser = browser

        let service = NetService(domain: "local.", type: "\(Self.serviceType).", name: "SpokenOdysseyLocalNetwork", port: 1100)
        service.delegate = self
        self.service = service

        let item = DispatchWorkItem { [weak self] in self?.finish(.undetermined) }
        timeoutItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: item)

        browser.start(queue: .main)
        service.publish()
    }

    public func netServiceDidPublish(_ sender: NetService) {
        finish(.granted)
    }

    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        // Not a permission answer (e.g. a name clash); let the download try anyway.
        finish(.undetermined)
    }

    private func finish(_ status: Status) {
        guard let completion = completion else { return }
        self.completion = nil
        timeoutItem?.cancel()
        browser?.cancel()
        browser = nil
        service?.stop()
        service = nil
        if Self.active === self { Self.active = nil }
        completion(status)
    }
}
