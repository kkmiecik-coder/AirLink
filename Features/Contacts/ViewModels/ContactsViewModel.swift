//
//  ContactsViewModel.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

// MARK: - ContactsViewModel

/// ViewModel dla ekranu kontaktów w AirLink
/// Zarządza listą kontaktów, wyszukiwaniem, QR scanning i dodawaniem kontaktów
@Observable
final class ContactsViewModel {
    
    // MARK: - Dependencies
    
    private let contactService: ContactService
    private let qrService: QRService
    private let chatService: ChatService
    private let coordinator: NavigationCoordinator
    
    // MARK: - Contacts State
    
    /// Wszystkie kontakty
    private(set) var allContacts: [Contact] = []
    
    /// Pogrupowane kontakty (sekcje A-Z)
    private(set) var groupedContacts: [ContactSection] = []
    
    /// Przefiltrowane kontakty
    private(set) var filteredContacts: [Contact] = []
    
    /// Czy lista jest w trakcie ładowania
    private(set) var isLoading = true
    
    /// Czy odświeżanie jest w toku
    private(set) var isRefreshing = false
    
    /// Aktualny błąd
    private(set) var currentError: ContactsError?
    
    // MARK: - Search State
    
    /// Tekst wyszukiwania
    var searchText = "" {
        didSet {
            filterContacts()
        }
    }
    
    /// Czy search jest aktywny
    var isSearchActive = false
    
    /// Wybrany filtr
    var selectedFilter: ContactFilter = .all {
        didSet {
            filterContacts()
        }
    }
    
    // MARK: - QR State
    
    /// Czy QR scanner jest aktywny
    private(set) var isQRScannerActive = false
    
    /// Status uprawnień kamery
    private(set) var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    /// Czy QR został zeskanowany pomyślnie
    private(set) var qrScanResult: QRScanResult?
    
    /// Czy pokazać QR scan confirmation
    var shouldShowQRConfirmation: Bool {
        if case .success = qrScanResult {
            return true
        }
        return false
    }
    
    // MARK: - Selection State
    
    /// Wybrany kontakt (dla details)
    private(set) var selectedContact: Contact?
    
    /// Czy pokazać contact details
    var shouldShowContactDetails: Bool {
        selectedContact != nil
    }
    
    /// Kontakty wybrane do grupowej akcji
    var selectedContacts: Set<String> = []
    
    /// Czy w trybie wielokrotnego wyboru
    var isSelectionMode = false
    
    // MARK: - Add Contact State
    
    /// Czy pokazać add contact sheet
    private(set) var shouldShowAddContactSheet = false
    
    /// Dane kontaktu do dodania (z QR)
    private(set) var pendingContactData: ContactQRData?
    
    // MARK: - Statistics
    
    /// Liczba kontaktów online
    var onlineContactsCount: Int {
        allContacts.filter { $0.isOnline }.count
    }
    
    /// Liczba kontaktów offline
    var offlineContactsCount: Int {
        allContacts.count - onlineContactsCount
    }
    
    /// Liczba kontaktów przez mesh
    var meshContactsCount: Int {
        allContacts.filter { $0.isConnectedViaMesh }.count
    }
    
    // MARK: - Computed Properties
    
    /// Czy lista jest pusta
    var isEmpty: Bool {
        allContacts.isEmpty && !isLoading
    }
    
    /// Czy pokazać empty state
    var shouldShowEmptyState: Bool {
        isEmpty && searchText.isEmpty && selectedFilter == .all
    }
    
    /// Czy pokazać search empty state
    var shouldShowSearchEmptyState: Bool {
        filteredContacts.isEmpty && (!searchText.isEmpty || selectedFilter != .all) && !isLoading
    }
    
    /// Czy można skanować QR
    var canScanQR: Bool {
        qrService.canStartScanning()
    }
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(
        contactService: ContactService,
        qrService: QRService,
        chatService: ChatService,
        coordinator: NavigationCoordinator
    ) {
        self.contactService = contactService
        self.qrService = qrService
        self.chatService = chatService
        self.coordinator = coordinator
        
        setupObservers()
        loadContacts()
        checkCameraPermission()
    }
    
    // MARK: - Contact Loading
    
    /// Ładuje kontakty
    func loadContacts() {
        isLoading = true
        currentError = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshContacts()
        }
    }
    
    /// Odświeża listę kontaktów
    func refreshContacts() {
        isRefreshing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Pobierz kontakty z serwisu
            self.allContacts = self.contactService.getSortedContacts()
            self.updateGroupedContacts()
            self.filterContacts()
            
            self.isLoading = false
            self.isRefreshing = false
        }
    }
    
    /// Aktualizuje pogrupowane kontakty
    private func updateGroupedContacts() {
        let grouped = contactService.getGroupedContacts()
        
        groupedContacts = grouped.keys.sorted().map { letter in
            ContactSection(
                letter: letter,
                contacts: grouped[letter] ?? []
            )
        }
    }
    
    /// Filtruje kontakty
    private func filterContacts() {
        var filtered = allContacts
        
        // Filtruj po statusie
        switch selectedFilter {
        case .all:
            break
        case .online:
            filtered = filtered.filter { $0.isOnline }
        case .offline:
            filtered = filtered.filter { !$0.isOnline }
        case .mesh:
            filtered = filtered.filter { $0.isConnectedViaMesh }
        case .recent:
            filtered = contactService.getRecentContacts()
        }
        
        // Filtruj po tekście wyszukiwania
        if !searchText.isEmpty {
            filtered = contactService.searchContacts(query: searchText)
                .filter { contact in
                    // Zastosuj też filtr statusu do wyników wyszukiwania
                    switch selectedFilter {
                    case .all:
                        return true
                    case .online:
                        return contact.isOnline
                    case .offline:
                        return !contact.isOnline
                    case .mesh:
                        return contact.isConnectedViaMesh
                    case .recent:
                        return contactService.getRecentContacts().contains(contact)
                    }
                }
        }
        
        filteredContacts = filtered
    }
    
    // MARK: - Contact Actions
    
    /// Otwiera szczegóły kontaktu
    func openContactDetails(_ contact: Contact) {
        selectedContact = contact
        coordinator.openContactDetails(contact)
    }
    
    /// Zamyka szczegóły kontaktu
    func closeContactDetails() {
        selectedContact = nil
    }
    
    /// Tworzy czat z kontaktem
    func createChatWith(_ contact: Contact) {
        Task {
            do {
                let chat = try chatService.createDirectMessageChat(with: contact)
                
                await MainActor.run {
                    coordinator.openChat(chat)
                }
            } catch {
                await MainActor.run {
                    currentError = .chatCreationFailed(error)
                }
            }
        }
    }
    
    /// Usuwa kontakt
    func deleteContact(_ contact: Contact) {
        Task {
            do {
                try contactService.deleteContact(contact)
                
                await MainActor.run {
                    refreshContacts()
                }
            } catch {
                await MainActor.run {
                    currentError = .contactDeletionFailed(error)
                }
            }
        }
    }
    
    /// Aktualizuje pseudonim kontaktu
    func updateContactNickname(_ contact: Contact, newNickname: String) {
        Task {
            do {
                try contactService.updateContactNickname(contact, nickname: newNickname)
                
                await MainActor.run {
                    refreshContacts()
                }
            } catch {
                await MainActor.run {
                    currentError = .contactUpdateFailed(error)
                }
            }
        }
    }
    
    // MARK: - QR Scanner
    
    /// Sprawdza uprawnienia kamery
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Żąda uprawnień kamery
    func requestCameraPermission() async {
        let granted = await qrService.requestCameraPermission()
        
        await MainActor.run {
            self.cameraPermissionStatus = granted ? .authorized : .denied
        }
    }
    
    /// Rozpoczyna skanowanie QR
    func startQRScanning() {
        guard canScanQR else {
            if cameraPermissionStatus != .authorized {
                currentError = .cameraPermissionDenied
            }
            return
        }
        
        isQRScannerActive = true
        coordinator.showQRScanner()
    }
    
    /// Zatrzymuje skanowanie QR
    func stopQRScanning() {
        isQRScannerActive = false
        coordinator.hideQRScanner()
        qrScanResult = nil
    }
    
    /// Obsługuje wynik skanowania QR
    func handleQRScanResult(_ result: QRScanResult) {
        qrScanResult = result
        
        switch result {
        case .success(let contactData):
            pendingContactData = contactData
            shouldShowAddContactSheet = true
            stopQRScanning()
            
        case .failure(let error):
            currentError = .qrScanningFailed(error)
            stopQRScanning()
        }
    }
    
    /// Potwierdza dodanie kontaktu z QR
    func confirmAddContactFromQR() {
        guard let contactData = pendingContactData else { return }
        
        Task {
            do {
                try await qrService.addContactFromQR(contactData)
                
                await MainActor.run {
                    shouldShowAddContactSheet = false
                    pendingContactData = nil
                    refreshContacts()
                }
            } catch {
                await MainActor.run {
                    currentError = .contactAddFailed(error)
                }
            }
        }
    }
    
    /// Anuluje dodawanie kontaktu
    func cancelAddContact() {
        shouldShowAddContactSheet = false
        pendingContactData = nil
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
    func setFilter(_ filter: ContactFilter) {
        selectedFilter = filter
    }
    
    /// Resetuje filtry
    func resetFilters() {
        selectedFilter = .all
        searchText = ""
    }
    
    // MARK: - Selection Actions
    
    /// Włącza tryb wielokrotnego wyboru
    func enterSelectionMode() {
        isSelectionMode = true
        selectedContacts.removeAll()
    }
    
    /// Wyłącza tryb wielokrotnego wyboru
    func exitSelectionMode() {
        isSelectionMode = false
        selectedContacts.removeAll()
    }
    
    /// Przełącza wybór kontaktu
    func toggleContactSelection(_ contact: Contact) {
        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }
    
    /// Wybiera wszystkie kontakty
    func selectAllContacts() {
        selectedContacts = Set(filteredContacts.map { $0.id })
    }
    
    /// Odznacza wszystkie kontakty
    func deselectAllContacts() {
        selectedContacts.removeAll()
    }
    
    /// Usuwa wybrane kontakty
    func deleteSelectedContacts() {
        let contactsToDelete = allContacts.filter { selectedContacts.contains($0.id) }
        
        Task {
            do {
                for contact in contactsToDelete {
                    try contactService.deleteContact(contact)
                }
                
                await MainActor.run {
                    exitSelectionMode()
                    refreshContacts()
                }
            } catch {
                await MainActor.run {
                    currentError = .bulkDeletionFailed(error)
                }
            }
        }
    }
    
    /// Tworzy grupę z wybranymi kontaktami
    func createGroupWithSelected() {
        let selectedContactObjects = allContacts.filter { selectedContacts.contains($0.id) }
        
        guard !selectedContactObjects.isEmpty else { return }
        
        exitSelectionMode()
        coordinator.showGroupCreation()
        
        // Przekaż wybrane kontakty do group creation
        // TODO: Implementacja z GroupCreationViewModel
    }
    
    // MARK: - Error Handling
    
    /// Czyści błąd
    func clearError() {
        currentError = nil
    }
    
    /// Ponawia ostatnią akcję
    func retryLastAction() {
        clearError()
        refreshContacts()
    }
    
    /// Otwiera ustawienia aplikacji
    func openAppSettings() {
        qrService.openCameraSettings()
    }
    
    // MARK: - Lifecycle
    
    /// Wywoływane gdy view się pojawia
    func onAppear() {
        refreshContacts()
        checkCameraPermission()
    }
    
    /// Wywoływane gdy view znika
    func onDisappear() {
        endSearch()
        exitSelectionMode()
        stopQRScanning()
    }
    
    // MARK: - Private Methods
    
    /// Konfiguruje obserwatorów
    private func setupObservers() {
        // Obserwuj zmiany kontaktów
        contactService.contactsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshContacts()
            }
            .store(in: &cancellables)
        
        // Obserwuj wyniki QR
        qrService.qrCodeScannedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.handleQRScanResult(result)
            }
            .store(in: &cancellables)
        
        // Obserwuj błędy QR
        qrService.scanningErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.currentError = .qrScanningFailed(error)
            }
            .store(in: &cancellables)
        
        // Obserwuj zmiany uprawnień kamery
        qrService.cameraPermissionUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.cameraPermissionStatus = status
            }
            .store(in: &cancellables)
    }
}

// MARK: - Contact Filter

/// Filtry dla listy kontaktów
enum ContactFilter: String, CaseIterable {
    case all = "all"
    case online = "online"
    case offline = "offline"
    case mesh = "mesh"
    case recent = "recent"
    
    var title: String {
        switch self {
        case .all:
            return "Wszystkie"
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case .mesh:
            return "Mesh"
        case .recent:
            return "Ostatnie"
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "person.2"
        case .online:
            return "person.badge.plus"
        case .offline:
            return "person.badge.minus"
        case .mesh:
            return "network"
        case .recent:
            return "clock"
        }
    }
    
    var color: Color {
        switch self {
        case .all:
            return AirLinkColors.textSecondary
        case .online:
            return AirLinkColors.statusOnline
        case .offline:
            return AirLinkColors.statusOffline
        case .mesh:
            return AirLinkColors.statusMesh
        case .recent:
            return AirLinkColors.primary
        }
    }
}

// MARK: - Contact Section

/// Sekcja kontaktów (grupa alfabetyczna)
struct ContactSection: Identifiable {
    let id = UUID()
    let letter: String
    let contacts: [Contact]
    
    var isEmpty: Bool {
        contacts.isEmpty
    }
}

// MARK: - Contacts Error

enum ContactsError: LocalizedError, Identifiable {
    case contactAddFailed(Error)
    case contactDeletionFailed(Error)
    case contactUpdateFailed(Error)
    case chatCreationFailed(Error)
    case qrScanningFailed(QRServiceError)
    case cameraPermissionDenied
    case bulkDeletionFailed(Error)
    case loadingFailed
    
    var id: String {
        switch self {
        case .contactAddFailed:
            return "contact-add-failed"
        case .contactDeletionFailed:
            return "contact-deletion-failed"
        case .contactUpdateFailed:
            return "contact-update-failed"
        case .chatCreationFailed:
            return "chat-creation-failed"
        case .qrScanningFailed:
            return "qr-scanning-failed"
        case .cameraPermissionDenied:
            return "camera-permission-denied"
        case .bulkDeletionFailed:
            return "bulk-deletion-failed"
        case .loadingFailed:
            return "loading-failed"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .contactAddFailed:
            return "Nie udało się dodać kontaktu"
        case .contactDeletionFailed:
            return "Nie udało się usunąć kontaktu"
        case .contactUpdateFailed:
            return "Nie udało się zaktualizować kontaktu"
        case .chatCreationFailed:
            return "Nie udało się utworzyć czatu"
        case .qrScanningFailed(let qrError):
            return qrError.errorDescription
        case .cameraPermissionDenied:
            return "Brak dostępu do kamery"
        case .bulkDeletionFailed:
            return "Nie udało się usunąć kontaktów"
        case .loadingFailed:
            return "Nie udało się załadować kontaktów"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .contactAddFailed, .contactUpdateFailed:
            return "Sprawdź połączenie i spróbuj ponownie"
        case .contactDeletionFailed, .bulkDeletionFailed:
            return "Spróbuj ponownie za chwilę"
        case .chatCreationFailed:
            return "Sprawdź czy kontakt jest online"
        case .qrScanningFailed:
            return "Sprawdź oświetlenie i spróbuj ponownie"
        case .cameraPermissionDenied:
            return "Przejdź do Ustawień i włącz dostęp do kamery"
        case .loadingFailed:
            return "Odśwież listę kontaktów"
        }
    }
}

// MARK: - Extensions

extension ContactsViewModel {
    
    /// Sprawdza czy kontakt jest wybrany
    func isContactSelected(_ contact: Contact) -> Bool {
        selectedContacts.contains(contact.id)
    }
    
    /// Zwraca licznik wybranych kontaktów jako tekst
    var selectedContactsText: String {
        let count = selectedContacts.count
        if count == 0 {
            return "Wybierz kontakty"
        } else if count == 1 {
            return "1 kontakt"
        } else {
            return "\(count) kontaktów"
        }
    }
    
    /// Sprawdza czy można utworzyć grupę
    var canCreateGroup: Bool {
        selectedContacts.count >= 2
    }
    
    /// Formatuje status kontaktu
    func formatContactStatus(_ contact: Contact) -> String {
        if contact.isOnline {
            let signalText = "(\(contact.signalStrength)/5)"
            let meshText = contact.isConnectedViaMesh ? " 🌐" : ""
            return "Online \(signalText)\(meshText)"
        } else {
            return contact.lastSeenText
        }
    }
    
    /// Zwraca kolor dla statusu kontaktu
    func getContactStatusColor(_ contact: Contact) -> Color {
        if contact.isOnline {
            return contact.isConnectedViaMesh ? AirLinkColors.statusMesh : AirLinkColors.statusOnline
        } else {
            return AirLinkColors.statusOffline
        }
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension ContactsViewModel {
    
    /// Tworzy mock view model dla preview
    static func createMockViewModel() -> ContactsViewModel {
        let mockContactService = ContactService.createMockService()
        let mockQRService = QRService.createMockService()
        let mockChatService = ChatService.createMockService()
        let mockCoordinator = NavigationCoordinator.createMockCoordinator()
        
        let viewModel = ContactsViewModel(
            contactService: mockContactService,
            qrService: mockQRService,
            chatService: mockChatService,
            coordinator: mockCoordinator
        )
        
        // Dodaj przykładowe kontakty
        viewModel.allContacts = createMockContacts()
        viewModel.updateGroupedContacts()
        viewModel.filterContacts()
        viewModel.isLoading = false
        
        return viewModel
    }
    
    /// Tworzy przykładowe kontakty
    private static func createMockContacts() -> [Contact] {
        return [
            Contact.sampleContact,
            Contact.sampleOnlineContact,
            Contact.sampleMeshContact
        ]
    }
    
    /// Symuluje różne stany
    func simulateState(_ state: MockContactsState) {
        switch state {
        case .loading:
            isLoading = true
            allContacts = []
            
        case .empty:
            isLoading = false
            allContacts = []
            groupedContacts = []
            
        case .withContacts:
            isLoading = false
            allContacts = Self.createMockContacts()
            updateGroupedContacts()
            filterContacts()
            
        case .scanning:
            isQRScannerActive = true
            
        case .withQRResult:
            qrScanResult = .success(ContactQRData(
                id: "sample-id",
                nickname: "Jan Nowak",
                hasAvatar: true,
                version: 1
            ))
            
        case .selectionMode:
            isSelectionMode = true
            selectedContacts = Set(allContacts.prefix(2).map { $0.id })
            
        case .withError:
            currentError = .loadingFailed
        }
    }
}

enum MockContactsState {
    case loading
    case empty
    case withContacts
    case scanning
    case withQRResult
    case selectionMode
    case withError
}
#endif
