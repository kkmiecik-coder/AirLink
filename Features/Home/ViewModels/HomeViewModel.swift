//
//  Untitled.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - HomeViewModel

/// ViewModel dla ekranu głównego AirLink
/// Zarządza listą czatów, FAB actions i search functionality
@Observable
final class HomeViewModel {
    
    // MARK: - Dependencies
    
    private let chatService: ChatService
    private let contactService: ContactService
    private let connectivityService: ConnectivityService
    private let coordinator: NavigationCoordinator
    
    // MARK: - State
    
    /// Lista wszystkich czatów
    private(set) var allChats: [Chat] = []
    
    /// Przefiltrowane czaty do wyświetlenia
    private(set) var displayedChats: [Chat] = []
    
    /// Czy lista jest w trakcie ładowania
    private(set) var isLoading = true
    
    /// Czy odświeżanie jest w toku
    private(set) var isRefreshing = false
    
    /// Aktualny błąd
    private(set) var currentError: Error?
    
    /// Tekst wyszukiwania
    var searchText = "" {
        didSet {
            filterChats()
        }
    }
    
    /// Wybrany filtr
    var selectedFilter: ChatFilter = .all {
        didSet {
            filterChats()
        }
    }
    
    /// Czy search bar jest aktywny
    var isSearchActive = false
    
    /// Czy pokazać FAB
    private(set) var shouldShowFAB = true
    
    /// Czy FAB jest w expanded state
    var isFABExpanded = false
    
    // MARK: - Computed Properties
    
    /// Czy lista jest pusta
    var isEmpty: Bool {
        displayedChats.isEmpty && !isLoading
    }
    
    /// Czy pokazać empty state
    var shouldShowEmptyState: Bool {
        isEmpty && searchText.isEmpty && selectedFilter == .all
    }
    
    /// Czy pokazać search results empty state
    var shouldShowSearchEmptyState: Bool {
        isEmpty && (!searchText.isEmpty || selectedFilter != .all)
    }
    
    /// Liczba nieprzeczytanych wiadomości
    var totalUnreadCount: Int {
        allChats.reduce(0) { $0 + $1.unreadCount }
    }
    
    /// Liczba aktywnych czatów (z online uczestnikami)
    var activeChatsCount: Int {
        allChats.filter { $0.isActive }.count
    }
    
    /// Status connectivity jako tekst
    var connectivityStatusText: String {
        let onlineCount = contactService.onlineContacts.count
        let totalCount = contactService.contacts.count
        
        if onlineCount == 0 {
            return "Offline"
        } else if totalCount == 0 {
            return "Brak kontaktów"
        } else {
            return "\(onlineCount)/\(totalCount) online"
        }
    }
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(
        chatService: ChatService,
        contactService: ContactService,
        connectivityService: ConnectivityService,
        coordinator: NavigationCoordinator
    ) {
        self.chatService = chatService
        self.contactService = contactService
        self.connectivityService = connectivityService
        self.coordinator = coordinator
        
        setupObservers()
        loadChats()
    }
    
    // MARK: - Public Methods
    
    /// Ładuje czaty
    func loadChats() {
        isLoading = true
        currentError = nil
        
        // Symulacja ładowania
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshChats()
        }
    }
    
    /// Odświeża listę czatów
    func refreshChats() {
        isRefreshing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Pobierz aktualne czaty z serwisu
            self.allChats = self.chatService.getRecentChats()
            self.filterChats()
            
            self.isLoading = false
            self.isRefreshing = false
        }
    }
    
    /// Filtruje czaty na podstawie wyszukiwania i filtra
    private func filterChats() {
        var filtered = allChats
        
        // Filtruj po typie
        switch selectedFilter {
        case .all:
            break
        case .unread:
            filtered = filtered.filter { $0.unreadCount > 0 }
        case .groups:
            filtered = filtered.filter { $0.isGroup }
        case .direct:
            filtered = filtered.filter { $0.isDirectMessage }
        case .active:
            filtered = filtered.filter { $0.isActive }
        }
        
        // Filtruj po tekście wyszukiwania
        if !searchText.isEmpty {
            filtered = filtered.filter { chat in
                chat.displayName.localizedCaseInsensitiveContains(searchText) ||
                (chat.lastMessagePreview?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        displayedChats = filtered
    }
    
    // MARK: - Chat Actions
    
    /// Otwiera czat
    func openChat(_ chat: Chat) {
        // Oznacz jako przeczytany
        chatService.markChatAsRead(chat)
        
        // Otwórz przez coordinator
        coordinator.openChat(chat)
        
        // Ukryj FAB gdy w czacie
        shouldShowFAB = false
    }
    
    /// Usuwa czat
    func deleteChat(_ chat: Chat) {
        Task {
            do {
                try chatService.deleteChat(chat)
                await MainActor.run {
                    refreshChats()
                }
            } catch {
                await MainActor.run {
                    currentError = error
                }
            }
        }
    }
    
    /// Oznacza czat jako przeczytany/nieprzeczytany
    func toggleReadStatus(_ chat: Chat) {
        if chat.unreadCount > 0 {
            chatService.markChatAsRead(chat)
        } else {
            // Dodaj fake unread (dla testów)
            chat.incrementUnreadCount()
        }
        
        refreshChats()
    }
    
    /// Wycisza/odcisza czat
    func toggleMuteStatus(_ chat: Chat) {
        chat.toggleMute()
        
        do {
            try chatService.saveChanges()
            refreshChats()
        } catch {
            currentError = error
        }
    }
    
    // MARK: - FAB Actions
    
    /// Obsługuje kliknięcie FAB
    func handleFABTap() {
        if contactService.contacts.isEmpty {
            // Brak kontaktów - pokaż QR scanner
            coordinator.startAddContactFlow()
        } else {
            // Pokaż opcje nowego czatu
            coordinator.showNewChatSheet()
        }
    }
    
    /// Tworzy nowy czat z kontaktem
    func createNewChat(with contact: Contact) {
        Task {
            do {
                let chat = try chatService.createDirectMessageChat(with: contact)
                
                await MainActor.run {
                    coordinator.hideNewChatSheet()
                    coordinator.openChat(chat)
                }
            } catch {
                await MainActor.run {
                    currentError = error
                }
            }
        }
    }
    
    /// Tworzy nową grupę
    func createNewGroup(name: String, participants: [Contact]) {
        Task {
            do {
                let chat = try chatService.createGroupChat(name: name, participants: participants)
                
                await MainActor.run {
                    coordinator.hideGroupCreation()
                    coordinator.openChat(chat)
                }
            } catch {
                await MainActor.run {
                    currentError = error
                }
            }
        }
    }
    
    // MARK: - Search Actions
    
    /// Rozpoczyna wyszukiwanie
    func startSearch() {
        isSearchActive = true
    }
    
    /// Kończy wyszukiwanie
    func endSearch() {
        isSearchActive = false
        searchText = ""
    }
    
    /// Czyści wyszukiwanie
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Filter Actions
    
    /// Ustawia filtr
    func setFilter(_ filter: ChatFilter) {
        selectedFilter = filter
    }
    
    /// Resetuje filtry
    func resetFilters() {
        selectedFilter = .all
        searchText = ""
    }
    
    // MARK: - Connectivity Actions
    
    /// Odświeża status connectivity
    func refreshConnectivity() {
        connectivityService.start()
    }
    
    /// Sprawdza status urządzeń
    func checkDeviceStatus() {
        contactService.updateOnlineStatuses()
    }
    
    // MARK: - Error Handling
    
    /// Czyści błąd
    func clearError() {
        currentError = nil
    }
    
    /// Ponawia operację po błędzie
    func retryAfterError() {
        clearError()
        refreshChats()
    }
    
    // MARK: - Lifecycle
    
    /// Wywoływane gdy view się pojawia
    func onAppear() {
        shouldShowFAB = true
        refreshChats()
        checkDeviceStatus()
    }
    
    /// Wywoływane gdy view znika
    func onDisappear() {
        endSearch()
    }
    
    // MARK: - Private Methods
    
    /// Konfiguruje obserwatorów
    private func setupObservers() {
        // Obserwuj zmiany w czatach
        chatService.chatsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chats in
                self?.allChats = chats
                self?.filterChats()
            }
            .store(in: &cancellables)
        
        // Obserwuj nowe wiadomości
        chatService.newMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (chat, message) in
                self?.handleNewMessage(chat: chat, message: message)
            }
            .store(in: &cancellables)
        
        // Obserwuj zmiany połączeń
        connectivityService.peerConnectionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateChatActiveStatus()
            }
            .store(in: &cancellables)
        
        // Obserwuj zmiany kontaktów
        contactService.contactsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateChatActiveStatus()
            }
            .store(in: &cancellables)
    }
    
    /// Obsługuje nową wiadomość
    private func handleNewMessage(chat: Chat, message: Message) {
        // Przenieś czat na górę listy
        if let index = allChats.firstIndex(where: { $0.id == chat.id }) {
            allChats.remove(at: index)
            allChats.insert(chat, at: 0)
        }
        
        filterChats()
        
        // Pokazuj notification jeśli app w tle
        // TODO: Local notification handling
    }
    
    /// Aktualizuje status aktywności czatów
    private func updateChatActiveStatus() {
        for chat in allChats {
            chat.updateActiveStatus()
        }
        
        filterChats()
    }
}

// MARK: - Chat Filter

/// Filtry dla listy czatów
enum ChatFilter: String, CaseIterable {
    case all = "all"
    case unread = "unread"
    case groups = "groups"
    case direct = "direct"
    case active = "active"
    
    var title: String {
        switch self {
        case .all:
            return "Wszystkie"
        case .unread:
            return "Nieprzeczytane"
        case .groups:
            return "Grupy"
        case .direct:
            return "Prywatne"
        case .active:
            return "Aktywne"
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "message"
        case .unread:
            return "message.badge"
        case .groups:
            return "person.3"
        case .direct:
            return "person.2"
        case .active:
            return "antenna.radiowaves.left.and.right"
        }
    }
}

// MARK: - Home State

/// Stan ekranu głównego
enum HomeState {
    case loading
    case loaded([Chat])
    case empty
    case error(Error)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }
    
    var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Extensions

extension HomeViewModel {
    
    /// Sprawdza czy można tworzyć nowe czaty
    var canCreateNewChats: Bool {
        return !contactService.contacts.isEmpty
    }
    
    /// Zwraca sugerowane akcje dla pustego stanu
    var emptySuggestions: [EmptyStateAction] {
        if contactService.contacts.isEmpty {
            return [
                EmptyStateAction(
                    title: "Skanuj kod QR",
                    icon: "qrcode.viewfinder",
                    action: { self.coordinator.showQRScanner() }
                ),
                EmptyStateAction(
                    title: "Pokaż swój kod",
                    icon: "qrcode",
                    action: { self.coordinator.showQRDisplay() }
                )
            ]
        } else {
            return [
                EmptyStateAction(
                    title: "Nowy czat",
                    icon: "plus.message",
                    action: { self.coordinator.showNewChatSheet() }
                )
            ]
        }
    }
    
    /// Formatuje czas ostatniej wiadomości
    func formatLastMessageTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.unitsStyle = .abbreviated
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Zwraca preview ostatniej wiadomości
    func getLastMessagePreview(for chat: Chat) -> String {
        return chat.lastMessageDisplay
    }
}

// MARK: - Empty State Action

struct EmptyStateAction {
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - Preview & Testing

#if DEBUG
extension HomeViewModel {
    
    /// Tworzy mock view model dla preview
    static func createMockViewModel() -> HomeViewModel {
        let mockChatService = ChatService.createMockService()
        let mockContactService = ContactService.createMockService()
        let mockConnectivityService = ConnectivityService()
        let mockCoordinator = NavigationCoordinator.createMockCoordinator()
        
        let viewModel = HomeViewModel(
            chatService: mockChatService,
            contactService: mockContactService,
            connectivityService: mockConnectivityService,
            coordinator: mockCoordinator
        )
        
        // Dodaj przykładowe czaty
        viewModel.allChats = createMockChats()
        viewModel.filterChats()
        viewModel.isLoading = false
        
        return viewModel
    }
    
    /// Tworzy przykładowe czaty
    private static func createMockChats() -> [Chat] {
        let contacts = [
            Contact.sampleContact,
            Contact.sampleOnlineContact,
            Contact.sampleMeshContact
        ]
        
        return [
            Chat.sampleDirectMessage,
            Chat.sampleGroupChat,
            Chat.sampleEmptyChat
        ]
    }
    
    /// Symuluje różne stany
    func simulateState(_ state: MockHomeState) {
        switch state {
        case .loading:
            isLoading = true
            displayedChats = []
            
        case .empty:
            isLoading = false
            allChats = []
            displayedChats = []
            
        case .withChats:
            isLoading = false
            allChats = Self.createMockChats()
            filterChats()
            
        case .withUnread:
            simulateState(.withChats)
            allChats.forEach { $0.incrementUnreadCount() }
            filterChats()
            
        case .withError:
            isLoading = false
            currentError = HomeViewModelError.loadingFailed
        }
    }
}

enum MockHomeState {
    case loading
    case empty
    case withChats
    case withUnread
    case withError
}

enum HomeViewModelError: LocalizedError {
    case loadingFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed:
            return "Nie udało się załadować czatów"
        case .networkError:
            return "Błąd połączenia"
        }
    }
}
#endif
