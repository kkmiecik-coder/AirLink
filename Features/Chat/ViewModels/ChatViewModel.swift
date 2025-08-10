//
//  ChatViewModel.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI

// MARK: - ChatViewModel

/// ViewModel dla ekranu czatu w AirLink
/// Zarządza wiadomościami, wysyłaniem, scroll pozycją i media attachments
@Observable
final class ChatViewModel {
    
    // MARK: - Dependencies
    
    private let chatService: ChatService
    private let contactService: ContactService
    private let mediaService: MediaService
    private let coordinator: NavigationCoordinator
    
    // MARK: - Chat State
    
    /// Aktualny czat
    private(set) var chat: Chat
    
    /// Lista wiadomości do wyświetlenia
    private(set) var messages: [Message] = []
    
    /// Czy wiadomości są w trakcie ładowania
    private(set) var isLoadingMessages = true
    
    /// Czy ładowane są starsze wiadomości
    private(set) var isLoadingMore = false
    
    /// Czy można załadować więcej wiadomości
    private(set) var canLoadMore = true
    
    /// Offset dla paginacji wiadomości
    private var messageOffset = 0
    
    /// Limit wiadomości na stronę
    private let messageLimit = 50
    
    // MARK: - Input State
    
    /// Tekst wiadomości w input field
    var messageText = "" {
        didSet {
            handleTypingChange()
        }
    }
    
    /// Czy input field ma focus
    var isInputFocused = false {
        didSet {
            if isInputFocused {
                markChatAsRead()
            }
        }
    }
    
    /// Czy można wysłać wiadomość
    var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSendingMessage
    }
    
    /// Czy wiadomość jest w trakcie wysyłania
    private(set) var isSendingMessage = false
    
    // MARK: - Media State
    
    /// Wybrane zdjęcia do wysłania
    var selectedPhotos: [PhotosPickerItem] = [] {
        didSet {
            processSelectedPhotos()
        }
    }
    
    /// Przygotowane attachments
    private(set) var pendingAttachments: [MediaAttachment] = []
    
    /// Czy media są w trakcie przetwarzania
    private(set) var isProcessingMedia = false
    
    /// Progress przetwarzania media (0.0 - 1.0)
    private(set) var mediaProcessingProgress: Double = 0.0
    
    // MARK: - UI State
    
    /// Czy pokazać scroll to bottom button
    private(set) var shouldShowScrollToBottom = false
    
    /// ID ostatniej wyświetlonej wiadomości (dla scroll tracking)
    private var lastVisibleMessageID: String?
    
    /// Czy keyboard jest widoczny
    private(set) var isKeyboardVisible = false
    
    /// Wysokość keyboard
    private(set) var keyboardHeight: CGFloat = 0
    
    // MARK: - Connectivity State
    
    /// Status połączenia z uczestnikami
    private(set) var connectionStatus: ChatConnectionStatus = .unknown
    
    /// Lista uczestników online
    private(set) var onlineParticipants: [Contact] = []
    
    /// Czy wszyscy uczestnicy są online
    var allParticipantsOnline: Bool {
        chat.allParticipantsOnline
    }
    
    // MARK: - Error State
    
    /// Aktualny błąd
    private(set) var currentError: ChatError?
    
    /// Czy pokazać error alert
    var shouldShowError: Bool {
        currentError != nil
    }
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    
    // MARK: - Initializer
    
    init(
        chat: Chat,
        chatService: ChatService,
        contactService: ContactService,
        mediaService: MediaService,
        coordinator: NavigationCoordinator
    ) {
        self.chat = chat
        self.chatService = chatService
        self.contactService = contactService
        self.mediaService = mediaService
        self.coordinator = coordinator
        
        setupObservers()
        setupKeyboardObservers()
        loadInitialMessages()
        updateConnectionStatus()
    }
    
    deinit {
        typingTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Message Loading
    
    /// Ładuje początkowe wiadomości
    func loadInitialMessages() {
        isLoadingMessages = true
        messageOffset = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadMessages()
        }
    }
    
    /// Ładuje wiadomości
    private func loadMessages() {
        let newMessages = chatService.getMessages(
            for: chat,
            limit: messageLimit,
            offset: messageOffset
        )
        
        if messageOffset == 0 {
            // Pierwsze ładowanie
            messages = newMessages
        } else {
            // Dołączanie starszych wiadomości na górę
            messages = newMessages + messages
        }
        
        canLoadMore = newMessages.count == messageLimit
        isLoadingMessages = false
        isLoadingMore = false
    }
    
    /// Ładuje więcej starszych wiadomości
    func loadMoreMessages() {
        guard canLoadMore && !isLoadingMore && !isLoadingMessages else { return }
        
        isLoadingMore = true
        messageOffset += messageLimit
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadMessages()
        }
    }
    
    // MARK: - Message Sending
    
    /// Wysyła wiadomość tekstową
    func sendMessage() {
        guard canSendMessage else { return }
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        Task {
            await sendTextMessage(text)
        }
    }
    
    /// Wysyła wiadomość tekstową (async)
    private func sendTextMessage(_ text: String) async {
        await MainActor.run {
            isSendingMessage = true
        }
        
        do {
            try await chatService.sendTextMessage(to: chat, content: text)
            
            await MainActor.run {
                isSendingMessage = false
                scrollToBottom()
            }
            
        } catch {
            await MainActor.run {
                isSendingMessage = false
                currentError = .messageSendFailed(error)
            }
        }
    }
    
    /// Wysyła wiadomość ze zdjęciem
    func sendImageMessage(_ imageData: Data, caption: String = "") async {
        await MainActor.run {
            isSendingMessage = true
        }
        
        do {
            try await chatService.sendImageMessage(to: chat, imageData: imageData, caption: caption)
            
            await MainActor.run {
                isSendingMessage = false
                pendingAttachments.removeAll()
                scrollToBottom()
            }
            
        } catch {
            await MainActor.run {
                isSendingMessage = false
                currentError = .imageSendFailed(error)
            }
        }
    }
    
    /// Wysyła pending attachments
    func sendPendingAttachments() {
        guard !pendingAttachments.isEmpty else { return }
        
        Task {
            for attachment in pendingAttachments {
                if let imageData = attachment.toUIImage()?.jpegData(compressionQuality: 0.8) {
                    await sendImageMessage(imageData, caption: messageText)
                }
            }
            
            await MainActor.run {
                messageText = ""
                pendingAttachments.removeAll()
            }
        }
    }
    
    // MARK: - Media Handling
    
    /// Przetwarza wybrane zdjęcia
    private func processSelectedPhotos() {
        guard !selectedPhotos.isEmpty else { return }
        
        isProcessingMedia = true
        mediaProcessingProgress = 0.0
        
        Task {
            for (index, item) in selectedPhotos.enumerated() {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        
                        let attachment = try await mediaService.compressImageForTransfer(image)
                        
                        await MainActor.run {
                            pendingAttachments.append(attachment)
                            mediaProcessingProgress = Double(index + 1) / Double(selectedPhotos.count)
                        }
                    }
                } catch {
                    await MainActor.run {
                        currentError = .mediaProcessingFailed(error)
                    }
                }
            }
            
            await MainActor.run {
                isProcessingMedia = false
                selectedPhotos.removeAll()
            }
        }
    }
    
    /// Usuwa pending attachment
    func removePendingAttachment(_ attachment: MediaAttachment) {
        pendingAttachments.removeAll { $0.id == attachment.id }
    }
    
    /// Otwiera image picker
    func openImagePicker() {
        coordinator.showImagePicker()
    }
    
    // MARK: - Scroll Management
    
    /// Przewija do dołu
    func scrollToBottom() {
        // To będzie wywołane przez View z ScrollViewReader
    }
    
    /// Aktualizuje scroll position
    func updateScrollPosition(lastVisibleID: String?) {
        lastVisibleMessageID = lastVisibleID
        
        // Sprawdź czy pokazać scroll to bottom button
        if let lastID = lastVisibleID,
           let lastMessage = messages.last,
           lastID != lastMessage.id {
            shouldShowScrollToBottom = true
        } else {
            shouldShowScrollToBottom = false
        }
    }
    
    /// Obsługuje scroll to bottom button tap
    func handleScrollToBottomTap() {
        scrollToBottom()
        shouldShowScrollToBottom = false
    }
    
    // MARK: - Chat Actions
    
    /// Oznacza czat jako przeczytany
    func markChatAsRead() {
        chatService.markChatAsRead(chat)
    }
    
    /// Opuszcza czat (dla grup)
    func leaveChat() {
        guard chat.isGroup else { return }
        
        // TODO: Implementacja opuszczania grupy
        coordinator.goBack(in: .home)
    }
    
    /// Dodaje uczestnika do grupy
    func addParticipant(_ contact: Contact) {
        guard chat.isGroup else { return }
        
        Task {
            do {
                try chatService.addParticipant(contact, to: chat)
            } catch {
                await MainActor.run {
                    currentError = .participantAddFailed(error)
                }
            }
        }
    }
    
    /// Usuwa uczestnika z grupy
    func removeParticipant(_ contact: Contact) {
        guard chat.isGroup else { return }
        
        Task {
            do {
                try chatService.removeParticipant(contact, from: chat)
            } catch {
                await MainActor.run {
                    currentError = .participantRemoveFailed(error)
                }
            }
        }
    }
    
    // MARK: - Typing Indicators
    
    /// Obsługuje zmiany w pisaniu
    private func handleTypingChange() {
        typingTimer?.invalidate()
        
        if !messageText.isEmpty {
            // TODO: Wyślij typing indicator
            
            // Ustaw timer do zatrzymania typing
            typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                // TODO: Zatrzymaj typing indicator
            }
        }
    }
    
    // MARK: - Connectivity
    
    /// Aktualizuje status połączenia
    private func updateConnectionStatus() {
        onlineParticipants = chat.participants.filter { $0.isOnline }
        
        if onlineParticipants.isEmpty {
            connectionStatus = .offline
        } else if onlineParticipants.count == chat.participants.count {
            connectionStatus = .allOnline
        } else {
            connectionStatus = .partiallyOnline
        }
    }
    
    /// Ponawia próbę połączenia
    func retryConnection() {
        contactService.updateOnlineStatuses()
        updateConnectionStatus()
    }
    
    // MARK: - Error Handling
    
    /// Czyści błąd
    func clearError() {
        currentError = nil
    }
    
    /// Ponawia ostatnią akcję
    func retryLastAction() {
        clearError()
        
        // Spróbuj ponownie wysłać wiadomość jeśli była błęd wysyłania
        if !messageText.isEmpty {
            sendMessage()
        }
    }
    
    // MARK: - Lifecycle
    
    /// Wywoływane gdy view się pojawia
    func onAppear() {
        chatService.setActiveChat(chat)
        markChatAsRead()
        updateConnectionStatus()
    }
    
    /// Wywoływane gdy view znika
    func onDisappear() {
        chatService.setActiveChat(nil)
        typingTimer?.invalidate()
    }
    
    // MARK: - Private Methods
    
    /// Konfiguruje obserwatorów
    private func setupObservers() {
        // Obserwuj nowe wiadomości
        chatService.newMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (incomingChat, message) in
                if incomingChat.id == self?.chat.id {
                    self?.handleNewMessage(message)
                }
            }
            .store(in: &cancellables)
        
        // Obserwuj zmiany statusu wiadomości
        chatService.messageStatusUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (messageID, status) in
                self?.updateMessageStatus(messageID: messageID, status: status)
            }
            .store(in: &cancellables)
        
        // Obserwuj zmiany connectivity
        contactService.contactsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateConnectionStatus()
            }
            .store(in: &cancellables)
        
        // Obserwuj progress kompresji media
        mediaService.compressionProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.mediaProcessingProgress = progress
            }
            .store(in: &cancellables)
    }
    
    /// Konfiguruje obserwatorów keyboard
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardWillShow(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardWillHide(notification)
        }
    }
    
    /// Obsługuje pokazanie keyboard
    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        isKeyboardVisible = true
        keyboardHeight = keyboardFrame.height
        
        // Auto scroll do dołu gdy keyboard się pojawia
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollToBottom()
        }
    }
    
    /// Obsługuje ukrycie keyboard
    private func handleKeyboardWillHide(_ notification: Notification) {
        isKeyboardVisible = false
        keyboardHeight = 0
    }
    
    /// Obsługuje nową wiadomość
    private func handleNewMessage(_ message: Message) {
        messages.append(message)
        
        // Auto scroll jeśli user jest na dole
        if !shouldShowScrollToBottom {
            scrollToBottom()
        }
        
        // Oznacz jako przeczytane jeśli input ma focus
        if isInputFocused {
            message.markAsRead()
        }
    }
    
    /// Aktualizuje status wiadomości
    private func updateMessageStatus(messageID: String, status: DeliveryStatus) {
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].updateDeliveryStatus(status)
        }
    }
}

// MARK: - Chat Connection Status

enum ChatConnectionStatus {
    case unknown
    case offline
    case partiallyOnline
    case allOnline
    
    var description: String {
        switch self {
        case .unknown:
            return "Sprawdzanie połączenia..."
        case .offline:
            return "Wszyscy offline"
        case .partiallyOnline:
            return "Częściowo online"
        case .allOnline:
            return "Wszyscy online"
        }
    }
    
    var color: Color {
        switch self {
        case .unknown:
            return AirLinkColors.textTertiary
        case .offline:
            return AirLinkColors.statusOffline
        case .partiallyOnline:
            return AirLinkColors.statusWarning
        case .allOnline:
            return AirLinkColors.statusOnline
        }
    }
}

// MARK: - Chat Error

enum ChatError: LocalizedError, Identifiable {
    case messageSendFailed(Error)
    case imageSendFailed(Error)
    case mediaProcessingFailed(Error)
    case participantAddFailed(Error)
    case participantRemoveFailed(Error)
    case connectionFailed
    case permissionDenied
    
    var id: String {
        switch self {
        case .messageSendFailed:
            return "message-send-failed"
        case .imageSendFailed:
            return "image-send-failed"
        case .mediaProcessingFailed:
            return "media-processing-failed"
        case .participantAddFailed:
            return "participant-add-failed"
        case .participantRemoveFailed:
            return "participant-remove-failed"
        case .connectionFailed:
            return "connection-failed"
        case .permissionDenied:
            return "permission-denied"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .messageSendFailed:
            return "Nie udało się wysłać wiadomości"
        case .imageSendFailed:
            return "Nie udało się wysłać zdjęcia"
        case .mediaProcessingFailed:
            return "Błąd przetwarzania zdjęcia"
        case .participantAddFailed:
            return "Nie udało się dodać uczestnika"
        case .participantRemoveFailed:
            return "Nie udało się usunąć uczestnika"
        case .connectionFailed:
            return "Błąd połączenia"
        case .permissionDenied:
            return "Brak uprawnień"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .messageSendFailed, .imageSendFailed:
            return "Sprawdź połączenie i spróbuj ponownie"
        case .mediaProcessingFailed:
            return "Spróbuj z innym zdjęciem"
        case .participantAddFailed, .participantRemoveFailed:
            return "Sprawdź czy uczestnik jest online"
        case .connectionFailed:
            return "Sprawdź Bluetooth i spróbuj ponownie"
        case .permissionDenied:
            return "Przejdź do Ustawień aplikacji"
        }
    }
}

// MARK: - Extensions

extension ChatViewModel {
    
    /// Sprawdza czy wiadomość jest od obecnego użytkownika
    func isMessageFromCurrentUser(_ message: Message) -> Bool {
        return message.senderID == getCurrentUserID()
    }
    
    /// Sprawdza czy pokazać avatar nadawcy
    func shouldShowAvatar(for message: Message, at index: Int) -> Bool {
        // Pokaż avatar tylko dla wiadomości innych użytkowników w grupach
        guard chat.isGroup && !isMessageFromCurrentUser(message) else { return false }
        
        // Pokaż jeśli to ostatnia wiadomość od tego nadawcy
        if index == messages.count - 1 { return true }
        
        let nextMessage = messages[index + 1]
        return nextMessage.senderID != message.senderID
    }
    
    /// Sprawdza czy pokazać timestamp
    func shouldShowTimestamp(for message: Message, at index: Int) -> Bool {
        // Pokaż timestamp co 5 minut lub dla pierwszej wiadomości
        if index == 0 { return true }
        
        let previousMessage = messages[index - 1]
        let timeDifference = message.timestamp.timeIntervalSince(previousMessage.timestamp)
        return timeDifference > 300 // 5 minut
    }
    
    /// Formatuje timestamp
    func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pl_PL")
        return formatter.string(from: date)
    }
    
    /// Pobiera ID obecnego użytkownika
    private func getCurrentUserID() -> String {
        // W przyszłości z UserService/SettingsService
        return "current-user-id"
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension ChatViewModel {
    
    /// Tworzy mock view model dla preview
    static func createMockViewModel(chat: Chat = Chat.sampleDirectMessage) -> ChatViewModel {
        let mockChatService = ChatService.createMockService()
        let mockContactService = ContactService.createMockService()
        let mockMediaService = MediaService.createMockService()
        let mockCoordinator = NavigationCoordinator.createMockCoordinator()
        
        let viewModel = ChatViewModel(
            chat: chat,
            chatService: mockChatService,
            contactService: mockContactService,
            mediaService: mockMediaService,
            coordinator: mockCoordinator
        )
        
        // Dodaj przykładowe wiadomości
        viewModel.messages = createMockMessages()
        viewModel.isLoadingMessages = false
        
        return viewModel
    }
    
    /// Tworzy przykładowe wiadomości
    private static func createMockMessages() -> [Message] {
        return [
            Message.sampleTextMessage,
            Message.sampleDeliveredMessage,
            Message.sampleMeshMessage,
            Message.sampleImageMessage
        ]
    }
    
    /// Symuluje różne stany
    func simulateState(_ state: MockChatState) {
        switch state {
        case .loading:
            isLoadingMessages = true
            messages = []
            
        case .empty:
            isLoadingMessages = false
            messages = []
            
        case .withMessages:
            isLoadingMessages = false
            messages = Self.createMockMessages()
            
        case .sending:
            isSendingMessage = true
            messageText = "Wysyłam wiadomość..."
            
        case .processingMedia:
            isProcessingMedia = true
            mediaProcessingProgress = 0.7
            
        case .withError:
            currentError = .messageSendFailed(ChatViewModelError.mockError)
            
        case .offline:
            connectionStatus = .offline
            onlineParticipants = []
        }
    }
}

enum MockChatState {
    case loading
    case empty
    case withMessages
    case sending
    case processingMedia
    case withError
    case offline
}

enum ChatViewModelError: LocalizedError {
    case mockError
    
    var errorDescription: String? {
        return "Mock error for testing"
    }
}
#endif
