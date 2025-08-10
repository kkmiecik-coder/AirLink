//
//  NavigationCoordinator.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI
import Combine

// MARK: - NavigationCoordinator

/// Koordynator nawigacji dla aplikacji AirLink
/// Zarządza przepływami nawigacyjnymi, deep linkami i modal presentations
@Observable
final class NavigationCoordinator {
    
    // MARK: - Navigation State
    
    /// Aktualnie wybrana zakładka
    var selectedTab: TabItem = .home
    
    /// Stack nawigacji dla Home
    var homeNavigationPath = NavigationPath()
    
    /// Stack nawigacji dla Contacts
    var contactsNavigationPath = NavigationPath()
    
    /// Stack nawigacji dla Settings
    var settingsNavigationPath = NavigationPath()
    
    // MARK: - Modal State
    
    /// Czy pokazywany jest QR scanner
    var isShowingQRScanner = false
    
    /// Czy pokazywany jest QR display
    var isShowingQRDisplay = false
    
    /// Czy pokazywany jest image picker
    var isShowingImagePicker = false
    
    /// Czy pokazywany jest new chat sheet
    var isShowingNewChatSheet = false
    
    /// Czy pokazywany jest contact details
    var isShowingContactDetails = false
    
    /// Czy pokazywany jest group creation
    var isShowingGroupCreation = false
    
    // MARK: - Deep Link State
    
    /// Pending deep link do przetworzenia
    var pendingDeepLink: DeepLink?
    
    /// Czy aplikacja jest gotowa do obsługi deep linków
    var isReadyForDeepLinks = false
    
    // MARK: - Error Handling
    
    /// Aktualny błąd do wyświetlenia
    var currentError: AppError?
    
    /// Czy pokazywany jest error alert
    var isShowingError = false
    
    // MARK: - Publishers
    
    private let navigationEventSubject = PassthroughSubject<NavigationEvent, Never>()
    var navigationEventPublisher: AnyPublisher<NavigationEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    init() {
        setupDeepLinkHandling()
    }
    
    // MARK: - Tab Navigation
    
    /// Przełącza na wybraną zakładkę
    func switchToTab(_ tab: TabItem) {
        selectedTab = tab
        navigationEventSubject.send(.tabChanged(tab))
        
        // Sprawdź czy wymagane są uprawnienia
        if let requiredAction = tab.requiredAction() {
            handlePreAction(requiredAction)
        }
    }
    
    /// Przełącza na zakładkę i wykonuje akcję
    func switchToTab(_ tab: TabItem, action: TabAction) {
        switchToTab(tab)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performAction(action)
        }
    }
    
    // MARK: - Navigation Actions
    
    /// Wykonuje akcję nawigacyjną
    func performAction(_ action: TabAction) {
        switch action {
        case .showRecentChats:
            // Już jesteśmy na Home - scroll to top lub refresh
            break
            
        case .showContactsList:
            // Już jesteśmy na Contacts - scroll to top lub refresh
            break
            
        case .showMainSettings:
            // Już jesteśmy na Settings - scroll to top
            break
            
        case .showQRScanner:
            showQRScanner()
            
        case .showNewChat:
            showNewChatSheet()
        }
        
        navigationEventSubject.send(.actionPerformed(action))
    }
    
    // MARK: - Chat Navigation
    
    /// Otwiera czat
    func openChat(_ chat: Chat) {
        let destination = NavigationDestination.chat(chat)
        
        switch selectedTab {
        case .home:
            homeNavigationPath.append(destination)
        case .contacts:
            // Przełącz na Home i otwórz czat
            selectedTab = .home
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.homeNavigationPath.append(destination)
            }
        case .settings:
            // Przełącz na Home i otwórz czat
            selectedTab = .home
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.homeNavigationPath.append(destination)
            }
        }
        
        navigationEventSubject.send(.chatOpened(chat))
    }
    
    /// Tworzy nowy czat z kontaktem
    func createChatWith(_ contact: Contact) {
        let destination = NavigationDestination.newChatWith(contact)
        homeNavigationPath.append(destination)
        
        navigationEventSubject.send(.newChatCreated(contact))
    }
    
    // MARK: - Contact Navigation
    
    /// Otwiera szczegóły kontaktu
    func openContactDetails(_ contact: Contact) {
        let destination = NavigationDestination.contactDetails(contact)
        contactsNavigationPath.append(destination)
        
        navigationEventSubject.send(.contactDetailsOpened(contact))
    }
    
    /// Otwiera proces dodawania kontaktu
    func startAddContactFlow() {
        showQRScanner()
        navigationEventSubject.send(.addContactFlowStarted)
    }
    
    // MARK: - Modal Presentations
    
    /// Pokazuje QR scanner
    func showQRScanner() {
        isShowingQRScanner = true
    }
    
    /// Ukrywa QR scanner
    func hideQRScanner() {
        isShowingQRScanner = false
    }
    
    /// Pokazuje QR display (własny kod)
    func showQRDisplay() {
        isShowingQRDisplay = true
    }
    
    /// Ukrywa QR display
    func hideQRDisplay() {
        isShowingQRDisplay = false
    }
    
    /// Pokazuje new chat sheet
    func showNewChatSheet() {
        isShowingNewChatSheet = true
    }
    
    /// Ukrywa new chat sheet
    func hideNewChatSheet() {
        isShowingNewChatSheet = false
    }
    
    /// Pokazuje image picker
    func showImagePicker() {
        isShowingImagePicker = true
    }
    
    /// Ukrywa image picker
    func hideImagePicker() {
        isShowingImagePicker = false
    }
    
    /// Pokazuje group creation
    func showGroupCreation() {
        isShowingGroupCreation = true
    }
    
    /// Ukrywa group creation
    func hideGroupCreation() {
        isShowingGroupCreation = false
    }
    
    // MARK: - Deep Links
    
    /// Obsługuje deep link
    func handleDeepLink(_ link: DeepLink) {
        if isReadyForDeepLinks {
            processDeepLink(link)
        } else {
            pendingDeepLink = link
        }
    }
    
    /// Oznacza aplikację jako gotową do deep linków
    func setReadyForDeepLinks() {
        isReadyForDeepLinks = true
        
        if let pendingLink = pendingDeepLink {
            processDeepLink(pendingLink)
            pendingDeepLink = nil
        }
    }
    
    /// Przetwarza deep link
    private func processDeepLink(_ link: DeepLink) {
        switch link {
        case .openChat(let chatID):
            // Znajdź czat i otwórz
            // Implementacja z ChatService
            break
            
        case .openContact(let contactID):
            // Znajdź kontakt i otwórz szczegóły
            switchToTab(.contacts)
            // Implementacja z ContactService
            break
            
        case .scanQR:
            showQRScanner()
            
        case .showQR:
            showQRDisplay()
            
        case .newChat:
            switchToTab(.home)
            showNewChatSheet()
            
        case .settings(let section):
            switchToTab(.settings)
            // Navigate to specific settings section
            break
        }
        
        navigationEventSubject.send(.deepLinkProcessed(link))
    }
    
    // MARK: - Error Handling
    
    /// Pokazuje błąd
    func showError(_ error: AppError) {
        currentError = error
        isShowingError = true
        
        navigationEventSubject.send(.errorShown(error))
    }
    
    /// Ukrywa błąd
    func hideError() {
        currentError = nil
        isShowingError = false
    }
    
    // MARK: - Navigation Reset
    
    /// Resetuje nawigację dla zakładki
    func resetNavigation(for tab: TabItem) {
        switch tab {
        case .home:
            homeNavigationPath = NavigationPath()
        case .contacts:
            contactsNavigationPath = NavigationPath()
        case .settings:
            settingsNavigationPath = NavigationPath()
        }
        
        navigationEventSubject.send(.navigationReset(tab))
    }
    
    /// Resetuje całą nawigację
    func resetAllNavigation() {
        homeNavigationPath = NavigationPath()
        contactsNavigationPath = NavigationPath()
        settingsNavigationPath = NavigationPath()
        
        // Ukryj wszystkie modale
        hideAllModals()
        
        navigationEventSubject.send(.allNavigationReset)
    }
    
    /// Ukrywa wszystkie modale
    private func hideAllModals() {
        isShowingQRScanner = false
        isShowingQRDisplay = false
        isShowingImagePicker = false
        isShowingNewChatSheet = false
        isShowingContactDetails = false
        isShowingGroupCreation = false
        isShowingError = false
    }
    
    // MARK: - Permission Handling
    
    /// Obsługuje wymagane akcje przed pokazaniem zakładki
    private func handlePreAction(_ action: TabPreAction) {
        switch action {
        case .checkBluetoothPermission:
            // Sprawdź uprawnienia Bluetooth
            checkBluetoothPermission()
            
        case .checkCameraPermission:
            // Sprawdź uprawnienia kamery
            checkCameraPermission()
            
        case .checkPhotoLibraryPermission:
            // Sprawdź uprawnienia galerii
            checkPhotoLibraryPermission()
        }
    }
    
    private func checkBluetoothPermission() {
        // Implementacja sprawdzania uprawnień Bluetooth
        // Jeśli brak - pokaż alert z przejściem do ustawień
    }
    
    private func checkCameraPermission() {
        // Implementacja sprawdzania uprawnień kamery
    }
    
    private func checkPhotoLibraryPermission() {
        // Implementacja sprawdzania uprawnień galerii
    }
    
    // MARK: - Setup
    
    private func setupDeepLinkHandling() {
        // Konfiguracja obsługi deep linków
        // Nasłuchiwanie notyfikacji z AppDelegate/SceneDelegate
    }
}

// MARK: - Navigation Destination

/// Destynacje nawigacyjne
enum NavigationDestination: Hashable {
    case chat(Chat)
    case contactDetails(Contact)
    case newChatWith(Contact)
    case settings(SettingsSection)
    case qrScanner
    case qrDisplay
    
    var id: String {
        switch self {
        case .chat(let chat):
            return "chat-\(chat.id)"
        case .contactDetails(let contact):
            return "contact-\(contact.id)"
        case .newChatWith(let contact):
            return "newchat-\(contact.id)"
        case .settings(let section):
            return "settings-\(section.rawValue)"
        case .qrScanner:
            return "qr-scanner"
        case .qrDisplay:
            return "qr-display"
        }
    }
}

// MARK: - Deep Link

/// Deep linki aplikacji
enum DeepLink: Hashable {
    case openChat(String)
    case openContact(String)
    case scanQR
    case showQR
    case newChat
    case settings(SettingsSection)
    
    var url: URL? {
        let baseURL = "airlink://"
        
        switch self {
        case .openChat(let chatID):
            return URL(string: "\(baseURL)chat/\(chatID)")
        case .openContact(let contactID):
            return URL(string: "\(baseURL)contact/\(contactID)")
        case .scanQR:
            return URL(string: "\(baseURL)qr/scan")
        case .showQR:
            return URL(string: "\(baseURL)qr/show")
        case .newChat:
            return URL(string: "\(baseURL)chat/new")
        case .settings(let section):
            return URL(string: "\(baseURL)settings/\(section.rawValue)")
        }
    }
}

// MARK: - Settings Section

enum SettingsSection: String, CaseIterable {
    case profile = "profile"
    case privacy = "privacy"
    case storage = "storage"
    case about = "about"
}

// MARK: - Navigation Event

/// Wydarzenia nawigacyjne
enum NavigationEvent {
    case tabChanged(TabItem)
    case actionPerformed(TabAction)
    case chatOpened(Chat)
    case newChatCreated(Contact)
    case contactDetailsOpened(Contact)
    case addContactFlowStarted
    case deepLinkProcessed(DeepLink)
    case errorShown(AppError)
    case navigationReset(TabItem)
    case allNavigationReset
}

// MARK: - App Error

/// Błędy aplikacji
enum AppError: LocalizedError, Identifiable {
    case bluetoothNotAvailable
    case cameraNotAvailable
    case networkError(String)
    case contactNotFound
    case chatCreationFailed
    case qrScanningFailed
    case permissionDenied(String)
    
    var id: String {
        switch self {
        case .bluetoothNotAvailable:
            return "bluetooth-not-available"
        case .cameraNotAvailable:
            return "camera-not-available"
        case .networkError:
            return "network-error"
        case .contactNotFound:
            return "contact-not-found"
        case .chatCreationFailed:
            return "chat-creation-failed"
        case .qrScanningFailed:
            return "qr-scanning-failed"
        case .permissionDenied:
            return "permission-denied"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .bluetoothNotAvailable:
            return "Bluetooth nie jest dostępny. Włącz Bluetooth w ustawieniach."
        case .cameraNotAvailable:
            return "Kamera nie jest dostępna."
        case .networkError(let message):
            return "Błąd sieci: \(message)"
        case .contactNotFound:
            return "Nie znaleziono kontaktu."
        case .chatCreationFailed:
            return "Nie udało się utworzyć czatu."
        case .qrScanningFailed:
            return "Nie udało się zeskanować kodu QR."
        case .permissionDenied(let permission):
            return "Brak uprawnień: \(permission)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .bluetoothNotAvailable:
            return "Przejdź do Ustawień i włącz Bluetooth."
        case .cameraNotAvailable:
            return "Sprawdź czy inna aplikacja nie używa kamery."
        case .networkError:
            return "Sprawdź połączenie internetowe."
        case .contactNotFound:
            return "Spróbuj odświeżyć listę kontaktów."
        case .chatCreationFailed:
            return "Spróbuj ponownie za chwilę."
        case .qrScanningFailed:
            return "Sprawdź oświetlenie i spróbuj ponownie."
        case .permissionDenied:
            return "Przejdź do Ustawień aplikacji."
        }
    }
}

// MARK: - Navigation Extensions

extension NavigationCoordinator {
    
    /// Sprawdza czy można wrócić w nawigacji
    func canGoBack(in tab: TabItem) -> Bool {
        switch tab {
        case .home:
            return !homeNavigationPath.isEmpty
        case .contacts:
            return !contactsNavigationPath.isEmpty
        case .settings:
            return !settingsNavigationPath.isEmpty
        }
    }
    
    /// Wraca w nawigacji
    func goBack(in tab: TabItem) {
        switch tab {
        case .home:
            if !homeNavigationPath.isEmpty {
                homeNavigationPath.removeLast()
            }
        case .contacts:
            if !contactsNavigationPath.isEmpty {
                contactsNavigationPath.removeLast()
            }
        case .settings:
            if !settingsNavigationPath.isEmpty {
                settingsNavigationPath.removeLast()
            }
        }
    }
    
    /// Sprawdza czy jakiś modal jest otwarty
    var hasOpenModals: Bool {
        return isShowingQRScanner ||
               isShowingQRDisplay ||
               isShowingImagePicker ||
               isShowingNewChatSheet ||
               isShowingContactDetails ||
               isShowingGroupCreation ||
               isShowingError
    }
    
    /// Zwraca liczbę otwartych ekranów w tabbie
    func navigationDepth(for tab: TabItem) -> Int {
        switch tab {
        case .home:
            return homeNavigationPath.count
        case .contacts:
            return contactsNavigationPath.count
        case .settings:
            return settingsNavigationPath.count
        }
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension NavigationCoordinator {
    
    /// Tworzy mock coordinator dla preview i testów
    static func createMockCoordinator() -> NavigationCoordinator {
        let coordinator = NavigationCoordinator()
        coordinator.isReadyForDeepLinks = true
        return coordinator
    }
    
    /// Symuluje różne stany nawigacji
    func simulateNavigationState(_ state: MockNavigationState) {
        switch state {
        case .homeWithChat:
            selectedTab = .home
            // Symuluj otwarty czat
            
        case .contactsWithDetails:
            selectedTab = .contacts
            // Symuluj otwarte detale kontaktu
            
        case .settingsDeep:
            selectedTab = .settings
            // Symuluj głęboka nawigacja w ustawieniach
            
        case .withModals:
            isShowingQRScanner = true
            isShowingNewChatSheet = true
            
        case .withError:
            showError(.bluetoothNotAvailable)
        }
    }
}

enum MockNavigationState {
    case homeWithChat
    case contactsWithDetails
    case settingsDeep
    case withModals
    case withError
}
#endif

// MARK: - URL Handling

extension NavigationCoordinator {
    
    /// Parsuje URL do deep link
    static func parseDeepLink(from url: URL) -> DeepLink? {
        guard url.scheme == "airlink" else { return nil }
        
        let components = url.pathComponents.dropFirst() // Usuń "/"
        
        guard let firstComponent = components.first else { return nil }
        
        switch firstComponent {
        case "chat":
            if components.count > 1 {
                let chatID = components[1]
                return chatID == "new" ? .newChat : .openChat(chatID)
            }
            return nil
            
        case "contact":
            if components.count > 1 {
                return .openContact(components[1])
            }
            return nil
            
        case "qr":
            if components.count > 1 {
                return components[1] == "scan" ? .scanQR : .showQR
            }
            return nil
            
        case "settings":
            if components.count > 1,
               let section = SettingsSection(rawValue: components[1]) {
                return .settings(section)
            }
            return nil
            
        default:
            return nil
        }
    }
    
    /// Generuje URL dla deep link
    func generateURL(for deepLink: DeepLink) -> URL? {
        return deepLink.url
    }
}

// MARK: - Analytics Support

extension NavigationCoordinator {
    
    /// Trackuje event nawigacyjny
    private func trackNavigationEvent(_ event: NavigationEvent) {
        // Integracja z analytics service
        let eventName: String
        var parameters: [String: Any] = [:]
        
        switch event {
        case .tabChanged(let tab):
            eventName = "tab_changed"
            parameters["tab"] = tab.rawValue
            
        case .actionPerformed(let action):
            eventName = action.analyticsEvent
            
        case .chatOpened(let chat):
            eventName = "chat_opened"
            parameters["chat_type"] = chat.type.rawValue
            parameters["participant_count"] = chat.participantCount
            
        case .newChatCreated(let contact):
            eventName = "new_chat_created"
            parameters["contact_id"] = contact.id
            
        case .contactDetailsOpened(let contact):
            eventName = "contact_details_opened"
            parameters["contact_online"] = contact.isOnline
            
        case .addContactFlowStarted:
            eventName = "add_contact_flow_started"
            
        case .deepLinkProcessed(let link):
            eventName = "deep_link_processed"
            parameters["deep_link_type"] = String(describing: link)
            
        case .errorShown(let error):
            eventName = "error_shown"
            parameters["error_type"] = error.id
            
        case .navigationReset(let tab):
            eventName = "navigation_reset"
            parameters["tab"] = tab.rawValue
            
        case .allNavigationReset:
            eventName = "all_navigation_reset"
        }
        
        // Wysłanie eventu do analytics
        print("📊 Analytics: \(eventName) - \(parameters)")
    }
}
