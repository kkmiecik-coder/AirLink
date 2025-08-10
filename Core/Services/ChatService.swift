//
//  ChatService.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftData
import Combine

// MARK: - ChatService

/// Serwis odpowiedzialny za zarządzanie czatami i wiadomościami w AirLink
/// Obsługuje tworzenie czatów, wysyłanie/odbieranie wiadomości oraz synchronizację
@Observable
final class ChatService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let connectivityService: ConnectivityService
    private let contactService: ContactService
    
    /// Wszystkie czaty użytkownika
    private(set) var chats: [Chat] = []
    
    /// Aktywny czat (obecnie wyświetlany)
    private(set) var activeChat: Chat?
    
    /// Czy serwis jest aktywny
    private(set) var isActive = false
    
    /// Buffer wiadomości oczekujących na wysłanie
    private var outgoingMessageQueue: [QueuedMessage] = []
    
    /// Mapa delivery status dla wiadomości
    private var messageDeliveryStatus: [String: DeliveryStatus] = [:]
    
    // MARK: - Publishers
    
    private let chatsUpdatedSubject = PassthroughSubject<[Chat], Never>()
    var chatsUpdatedPublisher: AnyPublisher<[Chat], Never> {
        chatsUpdatedSubject.eraseToAnyPublisher()
    }
    
    private let newMessageSubject = PassthroughSubject<(Chat, Message), Never>()
    var newMessagePublisher: AnyPublisher<(Chat, Message), Never> {
        newMessageSubject.eraseToAnyPublisher()
    }
    
    private let messageStatusUpdatedSubject = PassthroughSubject<(String, DeliveryStatus), Never>()
    var messageStatusUpdatedPublisher: AnyPublisher<(String, DeliveryStatus), Never> {
        messageStatusUpdatedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(
        modelContext: ModelContext,
        connectivityService: ConnectivityService,
        contactService: ContactService
    ) {
        self.modelContext = modelContext
        self.connectivityService = connectivityService
        self.contactService = contactService
        
        setupMessageHandling()
        loadChats()
    }
    
    // MARK: - Lifecycle
    
    /// Rozpoczyna serwis czatów
    func start() {
        guard !isActive else { return }
        
        isActive = true
        loadChats()
        processOutgoingQueue()
        
        print("💬 ChatService started")
    }
    
    /// Zatrzymuje serwis czatów
    func stop() {
        guard isActive else { return }
        
        isActive = false
        activeChat = nil
        outgoingMessageQueue.removeAll()
        
        print("💬 ChatService stopped")
    }
    
    // MARK: - Chat Management
    
    /// Tworzy nowy czat z kontaktem (DM)
    func createDirectMessageChat(with contact: Contact) throws -> Chat {
        // Sprawdź czy już istnieje DM z tym kontaktem
        if let existingChat = findDirectMessageChat(with: contact) {
            return existingChat
        }
        
        let chat = Chat(
            name: nil, // DM nie ma nazwy - generuje się automatycznie
            type: .directMessage,
            participants: [contact]
        )
        
        modelContext.insert(chat)
        try saveChanges()
        
        loadChats()
        notifyChatsUpdated()
        
        print("💬 Created DM chat with \(contact.nickname)")
        return chat
    }
    
    /// Tworzy nowy czat grupowy
    func createGroupChat(name: String, participants: [Contact]) throws -> Chat {
        guard !participants.isEmpty else {
            throw ChatServiceError.noParticipants
        }
        
        guard participants.count <= AppConstants.Limits.maxGroupParticipants else {
            throw ChatServiceError.tooManyParticipants
        }
        
        let chat = Chat(
            name: name,
            type: .group,
            participants: participants
        )
        
        modelContext.insert(chat)
        try saveChanges()
        
        loadChats()
        notifyChatsUpdated()
        
        print("💬 Created group chat '\(name)' with \(participants.count) participants")
        return chat
    }
    
    /// Dodaje uczestnika do czatu grupowego
    func addParticipant(_ contact: Contact, to chat: Chat) throws {
        guard chat.isGroup else {
            throw ChatServiceError.cannotModifyDirectMessage
        }
        
        guard chat.participantCount < AppConstants.Limits.maxGroupParticipants else {
            throw ChatServiceError.tooManyParticipants
        }
        
        chat.addParticipant(contact)
        try saveChanges()
        
        // Wyślij system message o dodaniu uczestnika
        try sendSystemMessage(
            to: chat,
            content: "\(contact.nickname) dołączył(a) do grupy"
        )
        
        notifyChatsUpdated()
    }
    
    /// Usuwa uczestnika z czatu grupowego
    func removeParticipant(_ contact: Contact, from chat: Chat) throws {
        guard chat.isGroup else {
            throw ChatServiceError.cannotModifyDirectMessage
        }
        
        chat.removeParticipant(contact)
        try saveChanges()
        
        // Wyślij system message o usunięciu uczestnika
        try sendSystemMessage(
            to: chat,
            content: "\(contact.nickname) opuścił(a) grupę"
        )
        
        notifyChatsUpdated()
    }
    
    /// Usuwa czat
    func deleteChat(_ chat: Chat) throws {
        // Usuń wszystkie wiadomości z czatu
        for message in chat.messages {
            modelContext.delete(message)
        }
        
        modelContext.delete(chat)
        try saveChanges()
        
        // Jeśli to był aktywny czat, wyczyść
        if activeChat?.id == chat.id {
            activeChat = nil
        }
        
        loadChats()
        notifyChatsUpdated()
    }
    
    // MARK: - Message Sending
    
    /// Wysyła wiadomość tekstową
    func sendTextMessage(to chat: Chat, content: String) async throws {
        guard !content.isEmpty else {
            throw ChatServiceError.emptyMessage
        }
        
        guard content.count <= AppConstants.Limits.maxMessageLength else {
            throw ChatServiceError.messageTooLong
        }
        
        let message = Message(
            content: content,
            senderID: getCurrentUserID(),
            type: .text,
            chat: chat
        )
        
        // Dodaj do bazy lokalnie
        try addMessageToChat(message, chat: chat)
        
        // Wyślij przez sieć
        await sendMessageThroughNetwork(message, chat: chat)
    }
    
    /// Wysyła wiadomość ze zdjęciem
    func sendImageMessage(to chat: Chat, imageData: Data, caption: String = "") async throws {
        guard imageData.count <= AppConstants.Connectivity.maxImageSize else {
            throw ChatServiceError.imageTooLarge
        }
        
        // Utwórz MediaAttachment
        guard let attachment = MediaAttachment.createImageAttachment(from: UIImage(data: imageData)!) else {
            throw ChatServiceError.imageProcessingFailed
        }
        
        let message = Message(
            content: caption.isEmpty ? "📷 Zdjęcie" : caption,
            senderID: getCurrentUserID(),
            type: .image,
            chat: chat
        )
        
        // Dodaj załącznik
        message.addAttachment(attachment)
        
        // Dodaj do bazy lokalnie
        try addMessageToChat(message, chat: chat)
        
        // Wyślij przez sieć
        await sendMessageThroughNetwork(message, chat: chat)
    }
    
    /// Wysyła system message
    private func sendSystemMessage(to chat: Chat, content: String) throws {
        let message = Message(
            content: content,
            senderID: "system",
            type: .system,
            chat: chat
        )
        
        message.updateDeliveryStatus(.delivered)
        try addMessageToChat(message, chat: chat)
    }
    
    // MARK: - Message Receiving
    
    /// Obsługuje odebraną wiadomość z sieci
    func handleReceivedMessage(_ receivedMessage: ReceivedMessage) {
        Task {
            do {
                try await processReceivedMessage(receivedMessage)
            } catch {
                print("❌ Error processing received message: \(error)")
            }
        }
    }
    
    private func processReceivedMessage(_ receivedMessage: ReceivedMessage) async throws {
        // Znajdź nadawcę w kontaktach
        guard let sender = contactService.findContact(by: receivedMessage.senderID) else {
            print("⚠️ Received message from unknown contact: \(receivedMessage.senderID)")
            return
        }
        
        // Znajdź lub utwórz czat z nadawcą
        let chat = try findOrCreateChatForMessage(with: sender, messageType: receivedMessage.type)
        
        // Utwórz wiadomość
        let message = Message(
            id: receivedMessage.id,
            content: receivedMessage.content,
            senderID: receivedMessage.senderID,
            type: receivedMessage.type,
            chat: chat
        )
        
        // Ustaw informacje o mesh
        message.setMeshInfo(
            sentViaMesh: receivedMessage.hops > 0,
            hops: receivedMessage.hops
        )
        
        message.updateDeliveryStatus(.delivered)
        
        // Dodaj załączniki jeśli są
        for attachmentData in receivedMessage.attachments {
            if let attachment = createAttachmentFromData(attachmentData, type: receivedMessage.type) {
                message.addAttachment(attachment)
            }
        }
        
        // Dodaj do czatu
        try addMessageToChat(message, chat: chat)
        
        // Powiadom o nowej wiadomości
        newMessageSubject.send((chat, message))
        
        print("📥 Processed message from \(sender.nickname) in chat '\(chat.displayName)'")
    }
    
    // MARK: - Active Chat Management
    
    /// Ustawia aktywny czat
    func setActiveChat(_ chat: Chat?) {
        activeChat = chat
        
        // Oznacz wiadomości jako przeczytane
        if let chat = chat {
            markChatAsRead(chat)
        }
    }
    
    /// Oznacza czat jako przeczytany
    func markChatAsRead(_ chat: Chat) {
        guard chat.unreadCount > 0 else { return }
        
        chat.markAsRead()
        
        // Oznacz wiadomości jako przeczytane
        for message in chat.messages where !message.isRead {
            message.markAsRead()
        }
        
        do {
            try saveChanges()
            notifyChatsUpdated()
        } catch {
            print("❌ Error marking chat as read: \(error)")
        }
    }
    
    // MARK: - Chat Queries
    
    /// Znajduje czat DM z kontaktem
    func findDirectMessageChat(with contact: Contact) -> Chat? {
        return chats.first { chat in
            chat.isDirectMessage &&
            chat.participants.count == 1 &&
            chat.participants.first?.id == contact.id
        }
    }
    
    /// Zwraca ostatnie czaty posortowane według aktywności
    func getRecentChats() -> [Chat] {
        return chats.sorted { chat1, chat2 in
            let date1 = chat1.lastMessageDate ?? chat1.dateCreated
            let date2 = chat2.lastMessageDate ?? chat2.dateCreated
            return date1 > date2
        }
    }
    
    /// Zwraca czaty grupowe
    func getGroupChats() -> [Chat] {
        return chats.filter { $0.isGroup }
    }
    
    /// Zwraca czaty z nieprzeczytanymi wiadomościami
    func getUnreadChats() -> [Chat] {
        return chats.filter { $0.unreadCount > 0 }
    }
    
    /// Zwraca całkowitą liczbę nieprzeczytanych wiadomości
    func getTotalUnreadCount() -> Int {
        return chats.reduce(0) { $0 + $1.unreadCount }
    }
    
    // MARK: - Message Queries
    
    /// Zwraca wiadomości dla czatu z paginacją
    func getMessages(for chat: Chat, limit: Int = 50, offset: Int = 0) -> [Message] {
        let allMessages = chat.messages.sorted { $0.timestamp < $1.timestamp }
        
        let startIndex = max(0, allMessages.count - offset - limit)
        let endIndex = max(0, allMessages.count - offset)
        
        if startIndex >= endIndex {
            return []
        }
        
        return Array(allMessages[startIndex..<endIndex])
    }
    
    /// Wyszukuje wiadomości po treści
    func searchMessages(query: String, in chat: Chat? = nil) -> [Message] {
        let searchableChats = chat != nil ? [chat!] : chats
        
        return searchableChats.flatMap { chat in
            chat.messages.filter { message in
                message.content.localizedCaseInsensitiveContains(query)
            }
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Private Methods
    
    /// Ładuje czaty z bazy danych
    private func loadChats() {
        let request = FetchDescriptor<Chat>(
            sortBy: [SortDescriptor(\.dateCreated)]
        )
        
        do {
            chats = try modelContext.fetch(request)
        } catch {
            print("❌ Error loading chats: \(error)")
            chats = []
        }
    }
    
    /// Zapisuje zmiany do bazy danych
    private func saveChanges() throws {
        try modelContext.save()
    }
    
    /// Powiadamia o aktualizacji czatów
    private func notifyChatsUpdated() {
        chatsUpdatedSubject.send(chats)
    }
    
    /// Dodaje wiadomość do czatu
    private func addMessageToChat(_ message: Message, chat: Chat) throws {
        modelContext.insert(message)
        chat.updateLastMessage(message)
        
        // Zwiększ unread count jeśli to nie nasza wiadomość i czat nie jest aktywny
        if message.senderID != getCurrentUserID() && activeChat?.id != chat.id {
            chat.incrementUnreadCount()
        }
        
        try saveChanges()
        notifyChatsUpdated()
    }
    
    /// Wysyła wiadomość przez sieć
    private func sendMessageThroughNetwork(_ message: Message, chat: Chat) async {
        // Ustaw status jako wysyłanie
        message.updateDeliveryStatus(.sending)
        messageStatusUpdatedSubject.send((message.id, .sending))
        
        do {
            // Przygotuj dane załączników
            let attachmentData = message.attachments.map { $0.compressedData }
            
            // Wyślij do wszystkich uczestników czatu
            for participant in chat.participants {
                guard participant.id != getCurrentUserID() else { continue }
                
                try await connectivityService.sendMessage(
                    to: participant.id,
                    content: message.content,
                    type: message.type,
                    attachments: attachmentData
                )
            }
            
            // Oznacz jako dostarczone
            message.updateDeliveryStatus(.delivered)
            messageStatusUpdatedSubject.send((message.id, .delivered))
            
        } catch {
            // Oznacz jako błąd i dodaj do queue
            message.updateDeliveryStatus(.failed)
            messageStatusUpdatedSubject.send((message.id, .failed))
            
            queueMessage(message, chat: chat)
            
            print("❌ Failed to send message: \(error)")
        }
    }
    
    /// Znajduje lub tworzy czat dla otrzymanej wiadomości
    private func findOrCreateChatForMessage(with sender: Contact, messageType: MessageType) throws -> Chat {
        // Sprawdź czy istnieje DM z tym kontaktem
        if let existingChat = findDirectMessageChat(with: sender) {
            return existingChat
        }
        
        // Utwórz nowy DM
        return try createDirectMessageChat(with: sender)
    }
    
    /// Tworzy załącznik z danych
    private func createAttachmentFromData(_ data: Data, type: MessageType) -> MediaAttachment? {
        switch type {
        case .image:
            guard let image = UIImage(data: data) else { return nil }
            return MediaAttachment.createImageAttachment(from: image)
        default:
            return nil
        }
    }
    
    /// Dodaje wiadomość do kolejki wysyłania
    private func queueMessage(_ message: Message, chat: Chat) {
        let queuedMessage = QueuedMessage(
            message: message,
            chat: chat,
            attempts: 0,
            lastAttempt: Date()
        )
        
        outgoingMessageQueue.append(queuedMessage)
    }
    
    /// Przetwarza kolejkę wiadomości wychodzących
    private func processOutgoingQueue() {
        guard isActive else { return }
        
        for (index, queuedMessage) in outgoingMessageQueue.enumerated().reversed() {
            Task {
                await sendMessageThroughNetwork(queuedMessage.message, chat: queuedMessage.chat)
                
                if queuedMessage.message.isDelivered {
                    outgoingMessageQueue.remove(at: index)
                } else {
                    outgoingMessageQueue[index].attempts += 1
                    outgoingMessageQueue[index].lastAttempt = Date()
                    
                    // Usuń po zbyt wielu próbach
                    if outgoingMessageQueue[index].attempts >= 3 {
                        outgoingMessageQueue.remove(at: index)
                    }
                }
            }
        }
    }
    
    /// Konfiguruje obsługę wiadomości z connectivity service
    private func setupMessageHandling() {
        connectivityService.messageReceivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receivedMessage in
                self?.handleReceivedMessage(receivedMessage)
            }
            .store(in: &cancellables)
    }
    
    /// Zwraca ID obecnego użytkownika
    private func getCurrentUserID() -> String {
        return connectivityService.localPeerID.displayName
    }
}

// MARK: - Data Models

struct QueuedMessage {
    let message: Message
    let chat: Chat
    var attempts: Int
    var lastAttempt: Date
}

// MARK: - Chat Service Errors

enum ChatServiceError: LocalizedError {
    case noParticipants
    case tooManyParticipants
    case cannotModifyDirectMessage
    case emptyMessage
    case messageTooLong
    case imageTooLarge
    case imageProcessingFailed
    case chatNotFound
    case messageNotFound
    case databaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noParticipants:
            return "Czat musi mieć przynajmniej jednego uczestnika"
        case .tooManyParticipants:
            return "Zbyt wielu uczestników w grupie (max \(AppConstants.Limits.maxGroupParticipants))"
        case .cannotModifyDirectMessage:
            return "Nie można modyfikować uczestników czatu prywatnego"
        case .emptyMessage:
            return "Wiadomość nie może być pusta"
        case .messageTooLong:
            return "Wiadomość jest zbyt długa (max \(AppConstants.Limits.maxMessageLength) znaków)"
        case .imageTooLarge:
            return "Zdjęcie jest zbyt duże"
        case .imageProcessingFailed:
            return "Nie udało się przetworzyć zdjęcia"
        case .chatNotFound:
            return "Nie znaleziono czatu"
        case .messageNotFound:
            return "Nie znaleziono wiadomości"
        case .databaseError(let error):
            return "Błąd bazy danych: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension ChatService {
    
    /// Sprawdza czy można wysłać wiadomość do czatu
    func canSendMessage(to chat: Chat) -> Bool {
        return chat.onlineParticipantsCount > 0
    }
    
    /// Zwraca statystyki czatów
    func getChatStatistics() -> ChatStatistics {
        let totalMessages = chats.reduce(0) { $0 + $1.messages.count }
        let totalUnread = getTotalUnreadCount()
        
        return ChatStatistics(
            totalChats: chats.count,
            groupChats: getGroupChats().count,
            directMessageChats: chats.count - getGroupChats().count,
            totalMessages: totalMessages,
            unreadMessages: totalUnread
        )
    }
}

struct ChatStatistics {
    let totalChats: Int
    let groupChats: Int
    let directMessageChats: Int
    let totalMessages: Int
    let unreadMessages: Int
}

// MARK: - Preview & Testing

#if DEBUG
extension ChatService {
    
    /// Tworzy mock service dla preview i testów
    static func createMockService() -> ChatService {
        let mockContext = MockModelContext()
        let mockConnectivity = MockConnectivityService()
        let mockContacts = ContactService.createMockService()
        
        let service = ChatService(
            modelContext: mockContext,
            connectivityService: mockConnectivity,
            contactService: mockContacts
        )
        
        // Dodaj przykładowe czaty
        // To będzie rozwinięte w testach
        
        return service
    }
}
#endif
