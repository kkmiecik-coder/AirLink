//
//  ConnectivityService.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import MultipeerConnectivity
import Network
import Combine

// MARK: - ConnectivityService

/// Serwis odpowiedzialny za łączność mesh network w AirLink
/// Obsługuje MultipeerConnectivity, routing mesh oraz monitoring siły sygnału
@Observable
final class ConnectivityService: NSObject {
    
    // MARK: - Properties
    
    /// MCPeerID dla lokalnego urządzenia
    let localPeerID: MCPeerID
    
    /// MCSession dla peer-to-peer communication
    private var session: MCSession
    
    /// Browser dla znajdowania innych urządzeń
    private var browser: MCNearbyServiceBrowser?
    
    /// Advertiser dla rozgłaszania obecności
    private var advertiser: MCNearbyServiceAdvertiser?
    
    /// Network monitor do śledzenia connectivity
    private let networkMonitor: NWPathMonitor
    
    /// Queue dla network operacji
    private let networkQueue = DispatchQueue(label: "com.airlink.network", qos: .userInitiated)
    
    // MARK: - State
    
    /// Czy serwis jest aktywny
    private(set) var isActive = false
    
    /// Połączone urządzenia
    private(set) var connectedPeers: [MCPeerID] = []
    
    /// Mapa siły sygnału dla połączonych urządzeń
    private var signalStrengthMap: [String: Int] = [:]
    
    /// Routing table dla mesh network
    private var meshRoutingTable: [String: MeshRoute] = [:]
    
    /// Buffer wiadomości oczekujących na wysłanie
    private var messageQueue: [PendingMessage] = []
    
    /// Timer do okresowych aktualizacji
    private var signalUpdateTimer: Timer?
    
    // MARK: - Publishers
    
    private let peerConnectionsSubject = PassthroughSubject<[MCPeerID], Never>()
    var peerConnectionsPublisher: AnyPublisher<[MCPeerID], Never> {
        peerConnectionsSubject.eraseToAnyPublisher()
    }
    
    private let signalStrengthSubject = PassthroughSubject<[String: Int], Never>()
    var signalStrengthPublisher: AnyPublisher<[String: Int], Never> {
        signalStrengthSubject.eraseToAnyPublisher()
    }
    
    private let messageReceivedSubject = PassthroughSubject<ReceivedMessage, Never>()
    var messageReceivedPublisher: AnyPublisher<ReceivedMessage, Never> {
        messageReceivedSubject.eraseToAnyPublisher()
    }
    
    private let meshRouteUpdatedSubject = PassthroughSubject<[String: MeshRoute], Never>()
    var meshRouteUpdatedPublisher: AnyPublisher<[String: MeshRoute], Never> {
        meshRouteUpdatedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    override init() {
        // Utwórz unikalny peer ID
        let deviceName = UIDevice.current.name
        self.localPeerID = MCPeerID(displayName: "\(deviceName)-\(UUID().uuidString.prefix(8))")
        
        // Konfiguruj session
        self.session = MCSession(
            peer: localPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        
        // Network monitor
        self.networkMonitor = NWPathMonitor()
        
        super.init()
        
        // Konfiguruj session delegate
        session.delegate = self
        
        // Uruchom network monitoring
        setupNetworkMonitoring()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Rozpoczyna serwis łączności
    func start() {
        guard !isActive else { return }
        
        isActive = true
        
        // Uruchom browser i advertiser
        startBrowsing()
        startAdvertising()
        
        // Uruchom timer aktualizacji sygnału
        startSignalMonitoring()
        
        print("🛜 ConnectivityService started with peer ID: \(localPeerID.displayName)")
    }
    
    /// Zatrzymuje serwis łączności
    func stop() {
        guard isActive else { return }
        
        isActive = false
        
        // Zatrzymaj browser i advertiser
        stopBrowsing()
        stopAdvertising()
        
        // Zatrzymaj monitoring
        stopSignalMonitoring()
        
        // Rozłącz wszystkie połączenia
        session.disconnect()
        connectedPeers.removeAll()
        
        // Wyczyść state
        signalStrengthMap.removeAll()
        meshRoutingTable.removeAll()
        messageQueue.removeAll()
        
        print("🛜 ConnectivityService stopped")
    }
    
    // MARK: - Message Sending
    
    /// Wysyła wiadomość do konkretnego odbiorcy
    func sendMessage(
        to recipientID: String,
        content: String,
        type: MessageType = .text,
        attachments: [Data] = []
    ) async throws {
        let message = OutgoingMessage(
            id: UUID().uuidString,
            recipientID: recipientID,
            content: content,
            type: type,
            attachments: attachments,
            timestamp: Date()
        )
        
        try await sendMessage(message)
    }
    
    /// Wysyła wiadomość (główna metoda)
    private func sendMessage(_ message: OutgoingMessage) async throws {
        // Sprawdź czy odbiorca jest bezpośrednio połączony
        if let directPeer = findDirectPeer(for: message.recipientID) {
            try await sendDirectMessage(message, to: directPeer)
            return
        }
        
        // Sprawdź routing table dla mesh route
        if let meshRoute = meshRoutingTable[message.recipientID] {
            try await sendMeshMessage(message, via: meshRoute)
            return
        }
        
        // Dodaj do queue i spróbuj znaleźć route
        queueMessage(message)
        await discoverRoute(for: message.recipientID)
    }
    
    /// Wysyła wiadomość bezpośrednio
    private func sendDirectMessage(_ message: OutgoingMessage, to peer: MCPeerID) async throws {
        let envelope = MessageEnvelope(
            message: message,
            route: MeshRoute(destination: message.recipientID, nextHop: peer.displayName, hops: 0)
        )
        
        let data = try JSONEncoder().encode(envelope)
        
        try session.send(data, toPeers: [peer], with: .reliable)
        
        print("📤 Sent direct message to \(peer.displayName)")
    }
    
    /// Wysyła wiadomość przez mesh
    private func sendMeshMessage(_ message: OutgoingMessage, via route: MeshRoute) async throws {
        guard let nextHopPeer = findDirectPeer(for: route.nextHop) else {
            throw ConnectivityError.routeNotAvailable
        }
        
        var updatedRoute = route
        updatedRoute.hops += 1
        
        let envelope = MessageEnvelope(
            message: message,
            route: updatedRoute
        )
        
        let data = try JSONEncoder().encode(envelope)
        
        try session.send(data, toPeers: [nextHopPeer], with: .reliable)
        
        print("📤 Sent mesh message to \(message.recipientID) via \(route.nextHop) (hops: \(updatedRoute.hops))")
    }
    
    // MARK: - Avatar Management
    
    /// Wysyła avatar do kontaktu
    func sendAvatar(to contactID: String, avatarData: Data) async throws {
        let message = OutgoingMessage(
            id: UUID().uuidString,
            recipientID: contactID,
            content: "avatar",
            type: .system,
            attachments: [avatarData],
            timestamp: Date()
        )
        
        try await sendMessage(message)
    }
    
    /// Żąda avatara od kontaktu
    func requestContactAvatar(contactID: String) async throws -> Data? {
        let message = OutgoingMessage(
            id: UUID().uuidString,
            recipientID: contactID,
            content: "avatar_request",
            type: .system,
            attachments: [],
            timestamp: Date()
        )
        
        try await sendMessage(message)
        
        // Czekaj na odpowiedź (implementacja z timeout)
        return try await waitForAvatarResponse(from: contactID)
    }
    
    // MARK: - Peer Management
    
    /// Zwraca listę ID połączonych urządzeń
    func getConnectedPeerIDs() -> [String] {
        return connectedPeers.map { $0.displayName }
    }
    
    /// Zwraca siłę sygnału dla konkretnego urządzenia
    func getSignalStrength(for peerID: String) -> Int {
        return signalStrengthMap[peerID] ?? 0
    }
    
    /// Sprawdza czy urządzenie jest połączone przez mesh
    func isConnectedViaMesh(_ peerID: String) -> Bool {
        return meshRoutingTable[peerID] != nil && meshRoutingTable[peerID]?.hops ?? 0 > 0
    }
    
    /// Znajduje bezpośredniego peera
    private func findDirectPeer(for peerID: String) -> MCPeerID? {
        return connectedPeers.first { $0.displayName == peerID }
    }
    
    // MARK: - Mesh Routing
    
    /// Odkrywa route do konkretnego urządzenia
    private func discoverRoute(for destinationID: String) async {
        let routeRequest = RouteDiscoveryMessage(
            destinationID: destinationID,
            originID: localPeerID.displayName,
            hops: 0
        )
        
        let data = try? JSONEncoder().encode(routeRequest)
        guard let data = data else { return }
        
        // Wysyłaj route discovery do wszystkich połączonych peers
        for peer in connectedPeers {
            try? session.send(data, toPeers: [peer], with: .unreliable)
        }
    }
    
    /// Aktualizuje routing table
    private func updateMeshRoute(_ route: MeshRoute) {
        let existingRoute = meshRoutingTable[route.destination]
        
        // Aktualizuj tylko jeśli nowa route ma mniej hopów lub nie ma istniejącej
        if existingRoute == nil || route.hops < existingRoute!.hops {
            meshRoutingTable[route.destination] = route
            meshRouteUpdatedSubject.send(meshRoutingTable)
            
            print("🗺️ Updated mesh route to \(route.destination) via \(route.nextHop) (\(route.hops) hops)")
        }
    }
    
    // MARK: - Signal Monitoring
    
    /// Uruchamia monitoring siły sygnału
    private func startSignalMonitoring() {
        signalUpdateTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Connectivity.signalUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateSignalStrengths()
        }
    }
    
    /// Zatrzymuje monitoring siły sygnału
    private func stopSignalMonitoring() {
        signalUpdateTimer?.invalidate()
        signalUpdateTimer = nil
    }
    
    /// Aktualizuje siły sygnału dla wszystkich połączonych urządzeń
    private func updateSignalStrengths() {
        var updatedStrengths: [String: Int] = [:]
        
        for peer in connectedPeers {
            // Symulacja siły sygnału (w rzeczywistości trzeba by wykorzystać RSSI lub inne metryki)
            let strength = calculateSignalStrength(for: peer)
            updatedStrengths[peer.displayName] = strength
        }
        
        signalStrengthMap = updatedStrengths
        signalStrengthSubject.send(updatedStrengths)
    }
    
    /// Kalkuluje siłę sygnału dla peera
    private func calculateSignalStrength(for peer: MCPeerID) -> Int {
        // W rzeczywistej implementacji można by wykorzystać:
        // - Network quality metrics
        // - Round-trip time
        // - Packet loss
        // - RSSI (jeśli dostępne)
        
        // Tymczasowa symulacja
        return Int.random(in: 1...5)
    }
    
    // MARK: - Browse & Advertise
    
    private func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: AppConstants.Connectivity.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        print("🔍 Started browsing for peers")
    }
    
    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        browser = nil
    }
    
    private func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerID,
            discoveryInfo: nil,
            serviceType: AppConstants.Connectivity.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        print("📢 Started advertising peer")
    }
    
    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
        advertiser = nil
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        print("🌐 Network path updated: \(path.status)")
        
        // Reaguj na zmiany stanu sieci
        if path.status == .satisfied {
            // Sieć dostępna - możemy kontynuować
            if isActive {
                processMessageQueue()
            }
        } else {
            // Brak sieci - możemy działać tylko przez Bluetooth
            print("⚠️ Network not satisfied, relying on Bluetooth only")
        }
    }
    
    // MARK: - Message Queue
    
    private func queueMessage(_ message: OutgoingMessage) {
        let pendingMessage = PendingMessage(
            message: message,
            attempts: 0,
            lastAttempt: Date()
        )
        
        messageQueue.append(pendingMessage)
        
        // Usuń stare wiadomości z queue
        cleanupMessageQueue()
    }
    
    private func processMessageQueue() {
        for (index, pendingMessage) in messageQueue.enumerated().reversed() {
            Task {
                do {
                    try await sendMessage(pendingMessage.message)
                    messageQueue.remove(at: index)
                } catch {
                    messageQueue[index].attempts += 1
                    messageQueue[index].lastAttempt = Date()
                    
                    // Usuń wiadomość po zbyt wielu próbach
                    if messageQueue[index].attempts >= 3 {
                        messageQueue.remove(at: index)
                    }
                }
            }
        }
    }
    
    private func cleanupMessageQueue() {
        let cutoff = Date().addingTimeInterval(-300) // 5 minut
        messageQueue.removeAll { $0.lastAttempt < cutoff }
    }
    
    // MARK: - Helper Methods
    
    private func waitForAvatarResponse(from contactID: String) async throws -> Data? {
        // Implementacja oczekiwania na odpowiedź z timeout
        // To będzie rozszerzone gdy będziemy mieć pełny message handling
        return nil
    }
}

// MARK: - MCSessionDelegate

extension ConnectivityService: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            self?.handlePeerStateChange(peerID, state: state)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(data, from: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Nie używamy streamów w tej implementacji
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Nie używamy zasobów w tej implementacji
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Nie używamy zasobów w tej implementacji
    }
    
    private func handlePeerStateChange(_ peerID: MCPeerID, state: MCSessionState) {
        switch state {
        case .connected:
            connectedPeers.append(peerID)
            print("✅ Connected to peer: \(peerID.displayName)")
            
        case .notConnected:
            connectedPeers.removeAll { $0 == peerID }
            signalStrengthMap.removeValue(forKey: peerID.displayName)
            // Usuń routes przez ten peer
            meshRoutingTable = meshRoutingTable.filter { $0.value.nextHop != peerID.displayName }
            print("❌ Disconnected from peer: \(peerID.displayName)")
            
        case .connecting:
            print("🔄 Connecting to peer: \(peerID.displayName)")
            
        @unknown default:
            break
        }
        
        peerConnectionsSubject.send(connectedPeers)
    }
    
    private func handleReceivedData(_ data: Data, from peerID: MCPeerID) {
        do {
            // Spróbuj zdekodować jako message envelope
            if let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data) {
                handleReceivedMessage(envelope, from: peerID)
                return
            }
            
            // Spróbuj zdekodować jako route discovery
            if let routeRequest = try? JSONDecoder().decode(RouteDiscoveryMessage.self, from: data) {
                handleRouteDiscovery(routeRequest, from: peerID)
                return
            }
            
            print("⚠️ Unknown data received from \(peerID.displayName)")
            
        } catch {
            print("❌ Error decoding data from \(peerID.displayName): \(error)")
        }
    }
    
    private func handleReceivedMessage(_ envelope: MessageEnvelope, from peerID: MCPeerID) {
        let message = envelope.message
        
        // Sprawdź czy wiadomość jest dla nas
        if message.recipientID == localPeerID.displayName {
            // Wiadomość dla nas
            let receivedMessage = ReceivedMessage(
                id: message.id,
                senderID: peerID.displayName,
                content: message.content,
                type: message.type,
                attachments: message.attachments,
                timestamp: message.timestamp,
                hops: envelope.route.hops
            )
            
            messageReceivedSubject.send(receivedMessage)
            print("📥 Received message from \(peerID.displayName) (hops: \(envelope.route.hops))")
        } else {
            // Wiadomość do przekazania (mesh relay)
            relayMessage(envelope, from: peerID)
        }
    }
    
    private func relayMessage(_ envelope: MessageEnvelope, from peerID: MCPeerID) {
        // Znajdź route do destinacji
        guard let route = meshRoutingTable[envelope.message.recipientID],
              let nextHopPeer = findDirectPeer(for: route.nextHop),
              nextHopPeer != peerID else { // Nie odsyłaj do nadawcy
            return
        }
        
        // Aktualizuj liczbę hopów
        var updatedEnvelope = envelope
        updatedEnvelope.route.hops += 1
        
        // Przekaż wiadomość
        if let data = try? JSONEncoder().encode(updatedEnvelope) {
            try? session.send(data, toPeers: [nextHopPeer], with: .reliable)
            print("🔄 Relayed message to \(envelope.message.recipientID) via \(nextHopPeer.displayName)")
        }
    }
    
    private func handleRouteDiscovery(_ request: RouteDiscoveryMessage, from peerID: MCPeerID) {
        // Jeśli szukają route do nas, odpowiedz
        if request.destinationID == localPeerID.displayName {
            let route = MeshRoute(
                destination: request.originID,
                nextHop: peerID.displayName,
                hops: request.hops + 1
            )
            updateMeshRoute(route)
        } else {
            // Propaguj request dalej (z ograniczeniem hopów)
            if request.hops < 5 {
                var forwardedRequest = request
                forwardedRequest.hops += 1
                
                if let data = try? JSONEncoder().encode(forwardedRequest) {
                    for peer in connectedPeers where peer != peerID {
                        try? session.send(data, toPeers: [peer], with: .unreliable)
                    }
                }
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ConnectivityService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Found peer: \(peerID.displayName)")
        
        // Automatycznie zaproś do sesji
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: AppConstants.Connectivity.connectionTimeout)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("🔍 Lost peer: \(peerID.displayName)")
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension ConnectivityService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📢 Received invitation from: \(peerID.displayName)")
        
        // Automatycznie akceptuj zaproszenie
        invitationHandler(true, session)
    }
}

// MARK: - Data Models

struct MessageEnvelope: Codable {
    let message: OutgoingMessage
    var route: MeshRoute
}

struct OutgoingMessage: Codable {
    let id: String
    let recipientID: String
    let content: String
    let type: MessageType
    let attachments: [Data]
    let timestamp: Date
}

struct ReceivedMessage {
    let id: String
    let senderID: String
    let content: String
    let type: MessageType
    let attachments: [Data]
    let timestamp: Date
    let hops: Int
}

struct MeshRoute: Codable {
    let destination: String
    let nextHop: String
    var hops: Int
}

struct RouteDiscoveryMessage: Codable {
    let destinationID: String
    let originID: String
    var hops: Int
}

struct PendingMessage {
    let message: OutgoingMessage
    var attempts: Int
    var lastAttempt: Date
}

// MARK: - Errors

enum ConnectivityError: LocalizedError {
    case notActive
    case peerNotFound
    case routeNotAvailable
    case messageTooLarge
    case sendFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notActive:
            return "Serwis łączności nie jest aktywny"
        case .peerNotFound:
            return "Nie znaleziono urządzenia docelowego"
        case .routeNotAvailable:
            return "Brak dostępnej trasy do urządzenia"
        case .messageTooLarge:
            return "Wiadomość jest zbyt duża"
        case .sendFailed(let error):
            return "Błąd wysyłania: \(error.localizedDescription)"
        }
    }
}
