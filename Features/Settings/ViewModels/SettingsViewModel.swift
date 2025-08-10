//
//  SettingsViewModel.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftUI
import Combine
import Photos

// MARK: - SettingsViewModel

/// ViewModel dla ekranu ustawień AirLink
/// Zarządza profilem użytkownika, storage, privacy i app settings
@Observable
final class SettingsViewModel {
    
    // MARK: - Dependencies
    
    private let storageService: StorageService
    private let mediaService: MediaService
    private let qrService: QRService
    private let coordinator: NavigationCoordinator
    
    // MARK: - Profile State
    
    /// Pseudonim użytkownika
    var userNickname = "Mój Pseudonim" {
        didSet {
            saveProfileChanges()
        }
    }
    
    /// Avatar użytkownika
    private(set) var userAvatarData: Data?
    
    /// Czy avatar jest w trakcie ładowania
    private(set) var isAvatarLoading = false
    
    /// Czy pokazać avatar picker
    var shouldShowAvatarPicker = false
    
    /// Czy pokazać avatar removal confirmation
    var shouldShowAvatarRemovalConfirmation = false
    
    // MARK: - Storage State
    
    /// Statystyki storage
    private(set) var storageStats = StorageStatistics()
    
    /// Czy cleanup jest w toku
    private(set) var isCleanupInProgress = false
    
    /// Progress cleanup (0.0 - 1.0)
    private(set) var cleanupProgress: Double = 0.0
    
    /// Czy pokazać storage details
    var shouldShowStorageDetails = false
    
    /// Czy pokazać cleanup confirmation
    var shouldShowCleanupConfirmation = false
    
    /// Opcje cleanup
    private(set) var cleanupOptions = CleanupOptions.default
    
    // MARK: - App Settings
    
    /// Czy haptic feedback jest włączony
    var isHapticFeedbackEnabled = true {
        didSet {
            saveAppSettings()
        }
    }
    
    /// Preferowany język aplikacji
    var preferredLanguage: AppLanguage = .system {
        didSet {
            saveAppSettings()
        }
    }
    
    /// Czy auto-cleanup jest włączony
    var isAutoCleanupEnabled = false {
        didSet {
            saveAppSettings()
        }
    }
    
    /// Interwał auto-cleanup (dni)
    var autoCleanupInterval = 30 {
        didSet {
            saveAppSettings()
        }
    }
    
    // MARK: - Privacy Settings
    
    /// Czy pokazywać avatar innym
    var showAvatarToOthers = true {
        didSet {
            savePrivacySettings()
        }
    }
    
    /// Czy automatycznie pobierać avatary kontaktów
    var autoDownloadAvatars = true {
        didSet {
            savePrivacySettings()
        }
    }
    
    /// Czy pokazywać status online
    var showOnlineStatus = true {
        didSet {
            savePrivacySettings()
        }
    }
    
    // MARK: - App Info
    
    /// Wersja aplikacji
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    /// Build number
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    /// Nazwa urządzenia
    let deviceName = UIDevice.current.name
    
    /// Model urządzenia
    let deviceModel = UIDevice.current.model
    
    /// Wersja iOS
    let iOSVersion = UIDevice.current.systemVersion
    
    // MARK: - Error State
    
    /// Aktualny błąd
    private(set) var currentError: SettingsError?
    
    /// Czy pokazać error alert
    var shouldShowError: Bool {
        currentError != nil
    }
    
    // MARK: - Success State
    
    /// Czy pokazać success message
    private(set) var shouldShowSuccessMessage = false
    
    /// Tekst success message
    private(set) var successMessage = ""
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(
        storageService: StorageService,
        mediaService: MediaService,
        qrService: QRService,
        coordinator: NavigationCoordinator
    ) {
        self.storageService = storageService
        self.mediaService = mediaService
        self.qrService = qrService
        self.coordinator = coordinator
        
        setupObservers()
        loadSettings()
        updateStorageStats()
    }
    
    // MARK: - Profile Management
    
    /// Ładuje ustawienia profilu
    func loadSettings() {
        // Load from UserDefaults or persistent storage
        loadProfileSettings()
        loadAppSettings()
        loadPrivacySettings()
    }
    
    /// Ładuje ustawienia profilu
    private func loadProfileSettings() {
        userNickname = UserDefaults.standard.string(forKey: "user_nickname") ?? "Mój Pseudonim"
        userAvatarData = UserDefaults.standard.data(forKey: "user_avatar")
    }
    
    /// Zapisuje zmiany profilu
    private func saveProfileChanges() {
        UserDefaults.standard.set(userNickname, forKey: "user_nickname")
        if let avatarData = userAvatarData {
            UserDefaults.standard.set(avatarData, forKey: "user_avatar")
        }
        
        // Regeneruj QR kod z nowym pseudonimem
        qrService.generateUserQRCode()
    }
    
    /// Aktualizuje avatar użytkownika
    func updateUserAvatar(_ imageData: Data) {
        isAvatarLoading = true
        
        Task {
            do {
                // Kompresuj avatar
                let image = UIImage(data: imageData)!
                let attachment = try await mediaService.compressImageForTransfer(image, quality: .balanced)
                
                await MainActor.run {
                    userAvatarData = attachment.compressedData
                    saveProfileChanges()
                    isAvatarLoading = false
                    showSuccessMessage("Avatar zaktualizowany")
                }
                
            } catch {
                await MainActor.run {
                    isAvatarLoading = false
                    currentError = .avatarUpdateFailed(error)
                }
            }
        }
    }
    
    /// Usuwa avatar użytkownika
    func removeUserAvatar() {
        userAvatarData = nil
        UserDefaults.standard.removeObject(forKey: "user_avatar")
        qrService.generateUserQRCode()
        showSuccessMessage("Avatar usunięty")
    }
    
    /// Pokazuje avatar picker
    func showAvatarPicker() {
        shouldShowAvatarPicker = true
    }
    
    /// Ukrywa avatar picker
    func hideAvatarPicker() {
        shouldShowAvatarPicker = false
    }
    
    /// Pokazuje confirmation do usunięcia avatara
    func showAvatarRemovalConfirmation() {
        shouldShowAvatarRemovalConfirmation = true
    }
    
    /// Ukrywa confirmation do usunięcia avatara
    func hideAvatarRemovalConfirmation() {
        shouldShowAvatarRemovalConfirmation = false
    }
    
    // MARK: - Storage Management
    
    /// Aktualizuje statystyki storage
    func updateStorageStats() {
        storageService.updateStorageStatistics()
    }
    
    /// Pokazuje szczegóły storage
    func showStorageDetails() {
        shouldShowStorageDetails = true
    }
    
    /// Ukrywa szczegóły storage
    func hideStorageDetails() {
        shouldShowStorageDetails = false
    }
    
    /// Rozpoczyna cleanup
    func startCleanup() {
        shouldShowCleanupConfirmation = true
    }
    
    /// Potwierdza cleanup
    func confirmCleanup() {
        shouldShowCleanupConfirmation = false
        
        Task {
            do {
                try await storageService.performCleanup(options: cleanupOptions)
                
                await MainActor.run {
                    updateStorageStats()
                    showSuccessMessage("Czyszczenie zakończone")
                }
                
            } catch {
                await MainActor.run {
                    currentError = .cleanupFailed(error)
                }
            }
        }
    }
    
    /// Anuluje cleanup
    func cancelCleanup() {
        shouldShowCleanupConfirmation = false
    }
    
    /// Aktualizuje opcje cleanup
    func updateCleanupOptions(_ options: CleanupOptions) {
        cleanupOptions = options
    }
    
    // MARK: - App Settings
    
    /// Ładuje ustawienia aplikacji
    private func loadAppSettings() {
        isHapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "haptic_feedback_enabled")
        isAutoCleanupEnabled = UserDefaults.standard.bool(forKey: "auto_cleanup_enabled")
        autoCleanupInterval = UserDefaults.standard.integer(forKey: "auto_cleanup_interval")
        
        if autoCleanupInterval == 0 {
            autoCleanupInterval = 30 // Default
        }
        
        if let languageCode = UserDefaults.standard.string(forKey: "preferred_language") {
            preferredLanguage = AppLanguage(rawValue: languageCode) ?? .system
        }
    }
    
    /// Zapisuje ustawienia aplikacji
    private func saveAppSettings() {
        UserDefaults.standard.set(isHapticFeedbackEnabled, forKey: "haptic_feedback_enabled")
        UserDefaults.standard.set(isAutoCleanupEnabled, forKey: "auto_cleanup_enabled")
        UserDefaults.standard.set(autoCleanupInterval, forKey: "auto_cleanup_interval")
        UserDefaults.standard.set(preferredLanguage.rawValue, forKey: "preferred_language")
    }
    
    /// Resetuje ustawienia aplikacji
    func resetAppSettings() {
        isHapticFeedbackEnabled = true
        preferredLanguage = .system
        isAutoCleanupEnabled = false
        autoCleanupInterval = 30
        
        saveAppSettings()
        showSuccessMessage("Ustawienia zresetowane")
    }
    
    // MARK: - Privacy Settings
    
    /// Ładuje ustawienia prywatności
    private func loadPrivacySettings() {
        showAvatarToOthers = UserDefaults.standard.bool(forKey: "show_avatar_to_others")
        autoDownloadAvatars = UserDefaults.standard.bool(forKey: "auto_download_avatars")
        showOnlineStatus = UserDefaults.standard.bool(forKey: "show_online_status")
    }
    
    /// Zapisuje ustawienia prywatności
    private func savePrivacySettings() {
        UserDefaults.standard.set(showAvatarToOthers, forKey: "show_avatar_to_others")
        UserDefaults.standard.set(autoDownloadAvatars, forKey: "auto_download_avatars")
        UserDefaults.standard.set(showOnlineStatus, forKey: "show_online_status")
    }
    
    /// Resetuje ustawienia prywatności
    func resetPrivacySettings() {
        showAvatarToOthers = true
        autoDownloadAvatars = true
        showOnlineStatus = true
        
        savePrivacySettings()
        showSuccessMessage("Ustawienia prywatności zresetowane")
    }
    
    // MARK: - QR Actions
    
    /// Pokazuje własny kod QR
    func showMyQRCode() {
        coordinator.showQRDisplay()
    }
    
    /// Rozpoczyna skanowanie QR
    func startQRScanning() {
        coordinator.showQRScanner()
    }
    
    // MARK: - Export/Import
    
    /// Eksportuje dane użytkownika
    func exportUserData() {
        Task {
            do {
                let exportData = try await storageService.exportDataForBackup()
                
                await MainActor.run {
                    // Pokaż share sheet z exportData
                    showShareSheet(data: exportData, filename: "airlink_backup.json")
                }
                
            } catch {
                await MainActor.run {
                    currentError = .exportFailed(error)
                }
            }
        }
    }
    
    /// Importuje dane użytkownika
    func importUserData(_ data: Data) {
        Task {
            do {
                try await storageService.importDataFromBackup(data)
                
                await MainActor.run {
                    updateStorageStats()
                    showSuccessMessage("Dane zaimportowane pomyślnie")
                }
                
            } catch {
                await MainActor.run {
                    currentError = .importFailed(error)
                }
            }
        }
    }
    
    // MARK: - External Actions
    
    /// Otwiera ustawienia aplikacji w Settings
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    /// Pokazuje informacje o aplikacji
    func showAboutApp() {
        // Navigate to about screen
        coordinator.switchToTab(.settings, action: .showMainSettings)
    }
    
    /// Otwiera wsparcie
    func openSupport() {
        guard let url = URL(string: "mailto:support@airlink.app") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Pokazuje informacje o prywatności
    func showPrivacyInfo() {
        // Navigate to privacy info screen
    }
    
    // MARK: - Error Handling
    
    /// Czyści błąd
    func clearError() {
        currentError = nil
    }
    
    /// Pokazuje success message
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        shouldShowSuccessMessage = true
        
        // Auto-hide po 3 sekundach
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.shouldShowSuccessMessage = false
        }
    }
    
    /// Ukrywa success message
    func hideSuccessMessage() {
        shouldShowSuccessMessage = false
    }
    
    // MARK: - Share Sheet
    
    private func showShareSheet(data: Data, filename: String) {
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            
            // Show share sheet via coordinator
            // TODO: Implement share sheet in coordinator
            
        } catch {
            currentError = .exportFailed(error)
        }
    }
    
    // MARK: - Lifecycle
    
    /// Wywoływane gdy view się pojawia
    func onAppear() {
        updateStorageStats()
    }
    
    // MARK: - Private Methods
    
    /// Konfiguruje obserwatorów
    private func setupObservers() {
        // Obserwuj zmiany storage stats
        storageService.storageStatsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.storageStats = stats
            }
            .store(in: &cancellables)
        
        // Obserwuj cleanup progress
        storageService.cleanupProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.cleanupProgress = progress
            }
            .store(in: &cancellables)
        
        // Obserwuj cleanup completion
        storageService.cleanupCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isCleanupInProgress = false
                
                switch result {
                case .success(let summary):
                    self?.showSuccessMessage("Zwolniono \(summary.formattedSpaceFreed)")
                case .failure(let error):
                    self?.currentError = .cleanupFailed(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case polish = "pl"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .system:
            return "Systemowy"
        case .polish:
            return "Polski"
        case .english:
            return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .system:
            return "🌐"
        case .polish:
            return "🇵🇱"
        case .english:
            return "🇺🇸"
        }
    }
}

// MARK: - Settings Error

enum SettingsError: LocalizedError, Identifiable {
    case avatarUpdateFailed(Error)
    case cleanupFailed(Error)
    case exportFailed(Error)
    case importFailed(Error)
    case settingsSaveFailed
    case permissionError
    
    var id: String {
        switch self {
        case .avatarUpdateFailed:
            return "avatar-update-failed"
        case .cleanupFailed:
            return "cleanup-failed"
        case .exportFailed:
            return "export-failed"
        case .importFailed:
            return "import-failed"
        case .settingsSaveFailed:
            return "settings-save-failed"
        case .permissionError:
            return "permission-error"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .avatarUpdateFailed:
            return "Nie udało się zaktualizować avatara"
        case .cleanupFailed:
            return "Nie udało się wyczyścić danych"
        case .exportFailed:
            return "Nie udało się wyeksportować danych"
        case .importFailed:
            return "Nie udało się zaimportować danych"
        case .settingsSaveFailed:
            return "Nie udało się zapisać ustawień"
        case .permissionError:
            return "Błąd uprawnień"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .avatarUpdateFailed:
            return "Spróbuj z innym zdjęciem"
        case .cleanupFailed:
            return "Spróbuj ponownie za chwilę"
        case .exportFailed, .importFailed:
            return "Sprawdź dostępne miejsce na dysku"
        case .settingsSaveFailed:
            return "Uruchom aplikację ponownie"
        case .permissionError:
            return "Sprawdź uprawnienia w Ustawieniach"
        }
    }
}

// MARK: - Extensions

extension SettingsViewModel {
    
    /// Sprawdza czy avatar użytkownika istnieje
    var hasUserAvatar: Bool {
        userAvatarData != nil
    }
    
    /// Zwraca UIImage avatara użytkownika
    var userAvatarImage: UIImage? {
        guard let data = userAvatarData else { return nil }
        return UIImage(data: data)
    }
    
    /// Sprawdza czy cleanup jest zalecany
    var isCleanupRecommended: Bool {
        storageService.needsCleanup()
    }
    
    /// Zwraca rekomendację storage
    var storageRecommendation: String {
        storageService.getCleanupRecommendation()
    }
    
    /// Formatuje rozmiar storage
    func formatStorageSize(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    /// Zwraca procent użytego miejsca
    var storageUsagePercentage: Double {
        let total = storageStats.usedSpace + storageStats.availableSpace
        guard total > 0 else { return 0 }
        return Double(storageStats.usedSpace) / Double(total)
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension SettingsViewModel {
    
    /// Tworzy mock view model dla preview
    static func createMockViewModel() -> SettingsViewModel {
        let mockStorageService = StorageService.createMockService()
        let mockMediaService = MediaService.createMockService()
        let mockQRService = QRService.createMockService()
        let mockCoordinator = NavigationCoordinator.createMockCoordinator()
        
        let viewModel = SettingsViewModel(
            storageService: mockStorageService,
            mediaService: mockMediaService,
            qrService: mockQRService,
            coordinator: mockCoordinator
        )
        
        // Ustaw przykładowe dane
        viewModel.userNickname = "Jan Kowalski"
        viewModel.storageStats = mockStorageService.storageStats
        
        return viewModel
    }
    
    /// Symuluje różne stany
    func simulateState(_ state: MockSettingsState) {
        switch state {
        case .withAvatar:
            // Symuluj avatar data
            userAvatarData = Data(repeating: 0, count: 1024)
            
        case .loadingAvatar:
            isAvatarLoading = true
            
        case .cleanupInProgress:
            isCleanupInProgress = true
            cleanupProgress = 0.6
            
        case .lowStorage:
            storageStats = StorageStatistics(
                totalMessages: 5000,
                totalChats: 50,
                totalContacts: 100,
                totalAttachments: 200,
                totalSize: 95 * 1024 * 1024, // 95MB
                availableSpace: 100 * 1024 * 1024 // 100MB available
            )
            
        case .withError:
            currentError = .settingsSaveFailed
            
        case .withSuccess:
            showSuccessMessage("Ustawienia zapisane")
        }
    }
}

enum MockSettingsState {
    case withAvatar
    case loadingAvatar
    case cleanupInProgress
    case lowStorage
    case withError
    case withSuccess
}
#endif
