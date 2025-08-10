//
//  ContactService.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftData
import MultipeerConnectivity
import Combine

// MARK: - ContactService

/// Serwis odpowiedzialny za zarządzanie kontaktami w AirLink
/// Obsługuje dodawanie, usuwanie, aktualizowanie kontaktów oraz śledzenie ich statusu online
@Observable
final class ContactService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let connectivityService: ConnectivityService
    
    /// Wszystkie kontakty użytkownika
    private(set) var contacts: [Contact] = []
    
    /// Kontakty obecnie online
    private(set) var onlineContacts: [Contact] = []
    
    /// Czy serwis jest aktywny
    private(set) var isActive = false
    
    /// Publisher dla zmian w kontaktach
    private let contactsSubject = PassthroughSubject<[Contact], Never>()
    var contactsPublisher: AnyPublisher<[Contact], Never> {
        contactsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext, connectivityService: ConnectivityService) {
        self.modelContext = modelContext
        self.connectivityService = connectivityService
        
        setupConnectivityObservers()
        loadContacts()
    }
    
    // MARK: - Public Methods
    
    /// Rozpoczyna serwis kontaktów
    func start() {
        guard !isActive else { return }
        
        isActive = true
        loadContacts()
        updateOnlineStatuses()
        
        // Subskrybuj zmiany connectivity
        connectivityService.start()
    }
    
    /// Zatrzymuje serwis kontaktów
    func stop() {
        guard isActive else { return }
        
        isActive = false
        clearOnlineStatuses()
        connectivityService.stop()
    }
    
    // MARK: - Contact Management
    
    /// Dodaje nowy kontakt z danymi QR
    func addContact(id: String, nickname: String, avatarData: Data? = nil) throws {
        // Sprawdź czy kontakt już istnieje
        if let existingContact = findContact(by: id) {
            // Aktualizuj istniejący kontakt
            existingContact.updateNickname(nickname)
            if let avatarData = avatarData {
                existingContact.updateAvatar(avatarData)
            }
            try saveChanges()
            return
        }
        
        // Utwórz nowy kontakt
        let newContact = Contact(
            id: id,
            nickname: nickname,
            avatarData: avatarData
        )
        
        modelContext.insert(newContact)
        try saveChanges()
        
        loadContacts()
        notifyContactsChanged()
    }
    
    /// Usuwa kontakt
    func deleteContact(_ contact: Contact) throws {
        modelContext.delete(contact)
        try saveChanges()
        
        loadContacts()
        notifyContactsChanged()
    }
    
    /// Aktualizuje nickname kontaktu
    func updateContactNickname(_ contact: Contact, nickname: String) throws {
        contact.updateNickname(nickname)
        try saveChanges()
        
        notifyContactsChanged()
    }
    
    /// Aktualizuje avatar kontaktu
    func updateContactAvatar(_ contact: Contact, avatarData: Data?) throws {
        contact.updateAvatar(avatarData)
        try saveChanges()
        
        notifyContactsChanged()
    }
    
    // MARK: - Contact Queries
    
    /// Znajduje kontakt po ID
    func findContact(by id: String) -> Contact? {
        return contacts.first { $0.id == id }
    }
    
    /// Znajduje kontakty po nickname (fuzzy search)
    func searchContacts(query: String) -> [Contact] {
        guard !query.isEmpty else { return contacts }
        
        return contacts.filter { contact in
            contact.nickname.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Zwraca kontakty posortowane alfabetycznie
    func getSortedContacts() -> [Contact] {
        return contacts.sorted { $0.nickname.localizedCompare($1.nickname) == .orderedAscending }
    }
    
    /// Zwraca kontakty pogrupowane według pierwszej litery
    func getGroupedContacts() -> [String: [Contact]] {
        let sortedContacts = getSortedContacts()
        
        return Dictionary(grouping: sortedContacts) { contact in
            String(contact.nickname.prefix(1).uppercased())
        }
    }
    
    /// Zwraca ostatnio aktywne kontakty
    func getRecentContacts(limit: Int = 10) -> [Contact] {
        return contacts
            .filter { $0.lastSeen != nil }
            .sorted { ($0.lastSeen ?? Date.distantPast) > ($1.lastSeen ?? Date.distantPast) }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Online Status Management
    
    /// Aktualizuje status online kontaktu
    func updateContactOnlineStatus(
        contactID: String,
        isOnline: Bool,
        signalStrength: Int = 0,
        viaMesh: Bool = false
    ) {
        guard let contact = findContact(by: contactID) else { return }
        
        contact.updateOnlineStatus(
            isOnline: isOnline,
            signalStrength: signalStrength,
            viaMesh: viaMesh
        )
        
        updateOnlineContactsList()
        notifyContactsChanged()
    }
    
    /// Aktualizuje wszystkie statusy online na podstawie connectivity service
    func updateOnlineStatuses() {
        let connectedPeerIDs = connectivityService.getConnectedPeerIDs()
        
        for contact in contacts {
            let isOnline = connectedPeerIDs.contains(contact.id)
            let signalStrength = isOnline ? connectivityService.getSignalStrength(for: contact.id) : 0
            let viaMesh = isOnline ? connectivityService.isConnectedViaMesh(contact.id) : false
            
            contact.updateOnlineStatus(
                isOnline: isOnline,
                signalStrength: signalStrength,
                viaMesh: viaMesh
            )
        }
        
        updateOnlineContactsList()
        notifyContactsChanged()
    }
    
    /// Czyści wszystkie statusy online
    private func clearOnlineStatuses() {
        for contact in contacts {
            contact.updateOnlineStatus(isOnline: false)
        }
        
        onlineContacts.removeAll()
        notifyContactsChanged()
    }
    
    // MARK: - Avatar Management
    
    /// Pobiera avatar kontaktu przez Bluetooth
    func fetchContactAvatar(contactID: String) async throws -> Data? {
        guard let contact = findContact(by: contactID), contact.isOnline else {
            throw ContactServiceError.contactNotOnline
        }
        
        // Poproś o avatar przez connectivity service
        return try await connectivityService.requestContactAvatar(contactID: contactID)
    }
    
    /// Wysyła avatar do kontaktu
    func sendAvatar(to contactID: String, avatarData: Data) async throws {
        guard findContact(by: contactID)?.isOnline == true else {
            throw ContactServiceError.contactNotOnline
        }
        
        try await connectivityService.sendAvatar(to: contactID, avatarData: avatarData)
    }
    
    // MARK: - Contact Export/Import
    
    /// Generuje dane do QR kodu dla udostępnienia kontaktu
    func generateContactQRData() throws -> Data {
        // Pobierz obecne ustawienia użytkownika (pseudonim, avatar)
        let userProfile = UserProfile.current // To będzie w SettingsService
        
        let contactData = ContactQRData(
            id: connectivityService.localPeerID.displayName,
            nickname: userProfile.nickname,
            hasAvatar: userProfile.avatarData != nil
        )
        
        return try JSONEncoder().encode(contactData)
    }
    
    /// Parsuje dane z QR kodu
    func parseContactQRData(_ data: Data) throws -> ContactQRData {
        return try JSONDecoder().decode(ContactQRData.self, from: data)
    }
    
    // MARK: - Statistics
    
    /// Zwraca statystyki kontaktów
    func getContactStatistics() -> ContactStatistics {
        return ContactStatistics(
            totalContacts: contacts.count,
            onlineContacts: onlineContacts.count,
            meshContacts: onlineContacts.filter { $0.isConnectedViaMesh }.count,
            recentlyActive: contacts.filter {
                guard let lastSeen = $0.lastSeen else { return false }
                return lastSeen > Date().addingTimeInterval(-24 * 60 * 60) // Last 24h
            }.count
        )
    }
    
    // MARK: - Private Methods
    
    /// Ładuje kontakty z bazy danych
    private func loadContacts() {
        let request = FetchDescriptor<Contact>(
            sortBy: [SortDescriptor(\.nickname)]
        )
        
        do {
            contacts = try modelContext.fetch(request)
            updateOnlineContactsList()
        } catch {
            print("Error loading contacts: \(error)")
            contacts = []
        }
    }
    
    /// Zapisuje zmiany do bazy danych
    private func saveChanges() throws {
        try modelContext.save()
    }
    
    /// Aktualizuje listę kontaktów online
    private func updateOnlineContactsList() {
        onlineContacts = contacts.filter { $0.isOnline }
    }
    
    /// Powiadamia o zmianach w kontaktach
    private func notifyContactsChanged() {
        contactsSubject.send(contacts)
    }
    
    /// Konfiguruje obserwatorów connectivity service
    private func setupConnectivityObservers() {
        // Obserwuj zmiany połączeń
        connectivityService.peerConnectionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateOnlineStatuses()
            }
            .store(in: &cancellables)
        
        // Obserwuj zmiany siły sygnału
        connectivityService.signalStrengthPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updates in
                self?.handleSignalStrengthUpdates(updates)
            }
            .store(in: &cancellables)
    }
    
    /// Obsługuje aktualizacje siły sygnału
    private func handleSignalStrengthUpdates(_ updates: [String: Int]) {
        for (contactID, strength) in updates {
            updateContactOnlineStatus(
                contactID: contactID,
                isOnline: strength > 0,
                signalStrength: strength,
                viaMesh: connectivityService.isConnectedViaMesh(contactID)
            )
        }
    }
}

// MARK: - Contact QR Data

/// Struktura danych przesyłanych w QR kodzie
struct ContactQRData: Codable {
    let id: String
    let nickname: String
    let hasAvatar: Bool
    let version: Int = 1  // Wersja dla kompatybilności
}

// MARK: - Contact Statistics

/// Statystyki kontaktów
struct ContactStatistics {
    let totalContacts: Int
    let onlineContacts: Int
    let meshContacts: Int
    let recentlyActive: Int
    
    var offlineContacts: Int {
        totalContacts - onlineContacts
    }
    
    var directContacts: Int {
        onlineContacts - meshContacts
    }
}

// MARK: - User Profile (Placeholder)

/// Placeholder dla profilu użytkownika - będzie w SettingsService
struct UserProfile {
    let nickname: String
    let avatarData: Data?
    
    static let current = UserProfile(nickname: "Ja", avatarData: nil)
}

// MARK: - Contact Service Errors

enum ContactServiceError: LocalizedError {
    case contactNotFound
    case contactAlreadyExists
    case contactNotOnline
    case invalidQRData
    case avatarFetchFailed
    case databaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .contactNotFound:
            return "Kontakt nie został znaleziony"
        case .contactAlreadyExists:
            return "Kontakt już istnieje"
        case .contactNotOnline:
            return "Kontakt nie jest online"
        case .invalidQRData:
            return "Nieprawidłowe dane QR kodu"
        case .avatarFetchFailed:
            return "Nie udało się pobrać avatara"
        case .databaseError(let error):
            return "Błąd bazy danych: \(error.localizedDescription)"
        }
    }
}

// MARK: - Contact Service Extensions

extension ContactService {
    
    /// Sprawdza czy można dodać nowy kontakt
    func canAddContact(id: String) -> Bool {
        return findContact(by: id) == nil
    }
    
    /// Sprawdza czy kontakt jest online
    func isContactOnline(id: String) -> Bool {
        return findContact(by: id)?.isOnline ?? false
    }
    
    /// Zwraca siłę sygnału kontaktu
    func getContactSignalStrength(id: String) -> Int {
        return findContact(by: id)?.signalStrength ?? 0
    }
    
    /// Sprawdza czy kontakt jest połączony przez mesh
    func isContactConnectedViaMesh(id: String) -> Bool {
        return findContact(by: id)?.isConnectedViaMesh ?? false
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension ContactService {
    
    /// Tworzy mock service dla preview i testów
    static func createMockService() -> ContactService {
        // Mock dependencies
        let mockContext = MockModelContext()
        let mockConnectivity = MockConnectivityService()
        
        let service = ContactService(
            modelContext: mockContext,
            connectivityService: mockConnectivity
        )
        
        // Dodaj przykładowe kontakty
        try? service.addContact(id: "user1", nickname: "Anna Kowalska")
        try? service.addContact(id: "user2", nickname: "Marek Nowak")
        try? service.addContact(id: "user3", nickname: "Kasia Wiśniewska")
        
        // Symuluj online statusy
        service.updateContactOnlineStatus(contactID: "user1", isOnline: true, signalStrength: 4)
        service.updateContactOnlineStatus(contactID: "user2", isOnline: true, signalStrength: 2, viaMesh: true)
        
        return service
    }
}

// Mock implementations (będą zastąpione prawdziwymi)
class MockModelContext: ModelContext {
    // Mock implementation
}

class MockConnectivityService: ConnectivityService {
    // Mock implementation
}
#endif
