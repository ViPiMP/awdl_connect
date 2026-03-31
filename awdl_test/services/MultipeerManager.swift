import Foundation
import MultipeerConnectivity
import Combine
import os.log

/// Manager class that handles all MultipeerConnectivity operations.
/// Uses AWDL interface for peer-to-peer connections without requiring a shared Wi-Fi network.
class MultipeerManager: NSObject, ObservableObject {
    var objectWillChange: ObservableObjectPublisher
    

    // MARK: - Constants

    /// Service type must be 1-15 characters, lowercase ASCII letters, numbers, and hyphens.
    private static let serviceType = "awdl-connect"

    // MARK: - Published Properties

    @Published var discoveredPeers: [PeerDevice] = []
    @Published var connectedPeers: [PeerDevice] = []
    @Published var messages: [PeerMessage] = []
    @Published var isAdvertising: Bool = false
    @Published var isBrowsing: Bool = false
    @Published var localDisplayName: String

    // MARK: - MultipeerConnectivity Properties

    private let myPeerID: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private let logger = Logger(subsystem: "com.awdl.connect", category: "MultipeerManager")

    // MARK: - Initialization

    init(displayName: String? = nil) {
        let name = displayName ?? UIDevice.current.name
        self.localDisplayName = name
        self.myPeerID = MCPeerID(displayName: name)
        self.objectWillChange = ObservableObjectPublisher()

        super.init()

        setupSession()
    }

    deinit {
        stopAll()
    }

    // MARK: - Session Setup

    private func setupSession() {
        // Create session with encryption preference.
        // MCSession uses AWDL (Apple Wireless Direct Link) by default on Apple devices
        // when peers are nearby, enabling direct peer-to-peer communication
        // without requiring both devices to be on the same Wi-Fi network.
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
        logger.info("Session created for peer: \(self.myPeerID.displayName)")
    }

    // MARK: - Advertising (Make this device discoverable)

    /// Start advertising this device to nearby peers via AWDL.
    func startAdvertising() {
        guard !isAdvertising else { return }

        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: ["device": UIDevice.current.model],
            serviceType: Self.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        DispatchQueue.main.async {
            self.isAdvertising = true
        }
        logger.info("Started advertising as: \(self.myPeerID.displayName)")
    }

    /// Stop advertising this device.
    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        DispatchQueue.main.async {
            self.isAdvertising = false
        }
        logger.info("Stopped advertising")
    }

    // MARK: - Browsing (Discover nearby peers)

    /// Start browsing for nearby peers via AWDL.
    func startBrowsing() {
        guard !isBrowsing else { return }

        browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: Self.serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        DispatchQueue.main.async {
            self.isBrowsing = true
        }
        logger.info("Started browsing for peers")
    }

    /// Stop browsing for peers.
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil

        DispatchQueue.main.async {
            self.isBrowsing = false
            self.discoveredPeers.removeAll()
        }
        logger.info("Stopped browsing")
    }

    // MARK: - Connection Management

    /// Invite a discovered peer to connect.
    func invitePeer(_ peer: PeerDevice) {
        guard let browser = browser else {
            logger.warning("Browser not available, cannot invite peer")
            return
        }

        // Update peer state to connecting
        updatePeerState(peer.id, state: .connecting)

        // Invite with a 30-second timeout
        browser.invitePeer(
            peer.id,
            to: session,
            withContext: nil,
            timeout: 30
        )
        logger.info("Invited peer: \(peer.displayName)")
    }

    /// Disconnect from a specific peer or all peers.
    func disconnect() {
        session.disconnect()
        DispatchQueue.main.async {
            self.connectedPeers.removeAll()
            // Reset discovered peers state
            self.discoveredPeers = self.discoveredPeers.map { peer in
                var updated = peer
                updated.state = .notConnected
                return updated
            }
        }
        logger.info("Disconnected from all peers")
    }

    /// Stop all services.
    func stopAll() {
        stopAdvertising()
        stopBrowsing()
        disconnect()
    }

    // MARK: - Messaging

    /// Send a text message to all connected peers.
    func sendMessage(_ text: String) {
        guard !session.connectedPeers.isEmpty else {
            logger.warning("No connected peers to send message to")
            return
        }

        let message = PeerMessage(senderName: localDisplayName, content: text)

        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)

            DispatchQueue.main.async {
                self.messages.append(message)
            }
            logger.info("Sent message to \(self.session.connectedPeers.count) peer(s)")
        } catch {
            logger.error("Failed to send message: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func updatePeerState(_ peerID: MCPeerID, state: MCSessionState) {
        DispatchQueue.main.async {
            // Update in discovered peers
            if let index = self.discoveredPeers.firstIndex(where: { $0.id == peerID }) {
                self.discoveredPeers[index].state = state
            }

            // Update connected peers list
            switch state {
            case .connected:
                let device = PeerDevice(
                    id: peerID,
                    displayName: peerID.displayName,
                    state: .connected
                )
                if !self.connectedPeers.contains(where: { $0.id == peerID }) {
                    self.connectedPeers.append(device)
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0.id == peerID }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let stateStr: String
        switch state {
        case .notConnected: stateStr = "Not Connected"
        case .connecting: stateStr = "Connecting"
        case .connected: stateStr = "Connected"
        @unknown default: stateStr = "Unknown"
        }
        logger.info("Peer \(peerID.displayName) changed state to: \(stateStr)")

        updatePeerState(peerID, state: state)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(PeerMessage.self, from: data)
            DispatchQueue.main.async {
                self.messages.append(message)
            }
            logger.info("Received message from: \(peerID.displayName)")
        } catch {
            logger.error("Failed to decode received data: \(error.localizedDescription)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        logger.info("Received stream from: \(peerID.displayName)")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        logger.info("Started receiving resource: \(resourceName) from: \(peerID.displayName)")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            logger.error("Failed to receive resource: \(error.localizedDescription)")
        } else {
            logger.info("Finished receiving resource: \(resourceName) from: \(peerID.displayName)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logger.info("Received invitation from: \(peerID.displayName)")

        // Automatically accept incoming invitations for this demo
        invitationHandler(true, session)
        logger.info("Accepted invitation from: \(peerID.displayName)")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        logger.error("Failed to start advertising: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isAdvertising = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerManager: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        logger.info("Found peer: \(peerID.displayName)")

        let device = PeerDevice(
            id: peerID,
            displayName: peerID.displayName,
            state: .notConnected
        )

        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(where: { $0.id == peerID }) {
                self.discoveredPeers.append(device)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        logger.info("Lost peer: \(peerID.displayName)")

        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0.id == peerID }
            self.connectedPeers.removeAll { $0.id == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        logger.error("Failed to start browsing: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isBrowsing = false
        }
    }
}
