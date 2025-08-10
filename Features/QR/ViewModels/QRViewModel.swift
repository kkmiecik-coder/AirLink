//
//  QRViewModel.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

// MARK: - QRViewModel

/// ViewModel dla QR functionality w AirLink
/// Zarządza wyświetlaniem i skanowaniem kodów QR
@Observable
final class QRViewModel {
    
    // MARK: - Dependencies
    
    private let qrService: QRService
    private let contactService: ContactService
    private let coordinator: NavigationCoordinator
    
    // MARK: - Display State
    
    /// Czy pokazuje własny QR kod
    var isDisplayMode = false
    
    /// Własny QR kod do wyświetlenia
    private(set) var userQRCode: UIImage?
    
    /// Czy QR kod jest w trakcie generowania
    private(set) var isGeneratingQR = false
    
    /// Custom style dla QR
    var qrDisplayStyle: QRDisplayStyle = .standard
    
    // MARK: - Scanner State
    
    /// Czy scanner jest aktywny
    private(set) var isScannerActive = false
    
    /// Preview layer dla kamery
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// Status uprawnień kamery
    private(set) var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    /// Czy można skanować
    var canScan: Bool {
        cameraPermissionStatus == .authorized && !isScannerActive
    }
    
    /// Ostatni zeskanowany kod
    private(set) var lastScannedCode: String?
    
    /// Czy pokazać viewfinder overlay
    var shouldShowViewfinder = true
    
    /// Czy pokazać flash toggle
    var shouldShowFlashToggle = false
    
    /// Czy flash jest włączony
    var isFlashEnabled = false {
        didSet {
            toggleFlash()
        }
    }
    
    // MARK: - Scan Result State
    
    /// Wynik skanowania
    private(set) var scanResult: QRScanResult?
    
    /// Czy pokazać scan result
    var shouldShowScanResult: Bool {
        scanResult != nil
    }
    
    /// Dane kontaktu z QR (jeśli udane skanowanie)
    var scannedContactData: ContactQRData? {
        if case .success(let data) = scanResult {
            return data
        }
        return nil
    }
    
    /// Błąd skanowania (jeśli nieudane)
    var scanError: QRServiceError? {
        if case .failure(let error) = scanResult {
            return error
        }
        return nil
    }
    
    // MARK: - Add Contact State
    
    /// Czy pokazać add contact confirmation
    var shouldShowAddContactConfirmation: Bool {
        scannedContactData != nil
    }
    
    /// Czy kontakt jest w trakcie dodawania
    private(set) var isAddingContact = false
    
    // MARK: - Error State
    
    /// Aktualny błąd
    private(set) var currentError: QRError?
    
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
        qrService: QRService,
        contactService: ContactService,
        coordinator: NavigationCoordinator
    ) {
        self.qrService = qrService
        self.contactService = contactService
        self.coordinator = coordinator
        
        setupObservers()
        checkCameraPermission()
        loadUserQRCode()
    }
    
    deinit {
        stopScanning()
    }
    
    // MARK: - QR Display
    
    /// Wchodzi w tryb wyświetlania QR
    func enterDisplayMode() {
        isDisplayMode = true
        loadUserQRCode()
    }
    
    /// Wychodzi z trybu wyświetlania QR
    func exitDisplayMode() {
        isDisplayMode = false
        coordinator.hideQRDisplay()
    }
    
    /// Ładuje własny QR kod
    func loadUserQRCode() {
        isGeneratingQR = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.userQRCode = self?.qrService.currentUserQRCode
            self?.isGeneratingQR = false
        }
    }
    
    /// Regeneruje QR kod
    func regenerateQRCode() {
        isGeneratingQR = true
        
        qrService.generateUserQRCode()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadUserQRCode()
        }
    }
    
    /// Aktualizuje styl wyświetlania QR
    func updateDisplayStyle(_ style: QRDisplayStyle) {
        qrDisplayStyle = style
        generateStyledQRCode()
    }
    
    /// Generuje QR z custom stylem
    private func generateStyledQRCode() {
        guard let userData = try? qrService.createUserQRData() else { return }
        
        isGeneratingQR = true
        
        Task {
            do {
                let styledQR = try qrService.generateStyledQRCode(
                    from: userData,
                    size: qrDisplayStyle.size,
                    foregroundColor: qrDisplayStyle.foregroundColor,
                    backgroundColor: qrDisplayStyle.backgroundColor
                )
                
                await MainActor.run {
                    userQRCode = styledQR
                    isGeneratingQR = false
                }
                
            } catch {
                await MainActor.run {
                    isGeneratingQR = false
                    currentError = .qrGenerationFailed(error)
                }
            }
        }
    }
    
    // MARK: - QR Scanning
    
    /// Sprawdza uprawnienia kamery
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Żąda uprawnień kamery
    func requestCameraPermission() async {
        let granted = await qrService.requestCameraPermission()
        
        await MainActor.run {
            cameraPermissionStatus = granted ? .authorized : .denied
            
            if granted {
                startScanning()
            } else {
                currentError = .cameraPermissionDenied
            }
        }
    }
    
    /// Rozpoczyna skanowanie
    func startScanning() {
        guard canScan else {
            if cameraPermissionStatus != .authorized {
                currentError = .cameraPermissionDenied
            }
            return
        }
        
        do {
            previewLayer = try qrService.startScanning()
            isScannerActive = true
            shouldShowFlashToggle = isFlashAvailable()
            
        } catch {
            currentError = .scannerStartFailed(error)
        }
    }
    
    /// Zatrzymuje skanowanie
    func stopScanning() {
        guard isScannerActive else { return }
        
        qrService.stopScanning()
        isScannerActive = false
        previewLayer = nil
        shouldShowFlashToggle = false
        isFlashEnabled = false
    }
    
    /// Ręczne skupienie kamery
    func focusCamera(at point: CGPoint) {
        guard isScannerActive else { return }
        qrService.focusCamera(at: point)
    }
    
    /// Przełącza flash
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashEnabled ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("❌ Failed to toggle flash: \(error)")
        }
    }
    
    /// Sprawdza czy flash jest dostępny
    private func isFlashAvailable() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.hasTorch && device.isTorchAvailable
    }
    
    // MARK: - Scan Result Handling
    
    /// Obsługuje wynik skanowania
    func handleScanResult(_ result: QRScanResult) {
        scanResult = result
        lastScannedCode = nil
        
        switch result {
        case .success(let contactData):
            // Zatrzymaj skanowanie po udanym odczycie
            stopScanning()
            
            // Sprawdź czy to nie własny QR
            if contactData.id == getCurrentUserID() {
                currentError = .cannotAddSelf
                return
            }
            
            // Sprawdź czy kontakt już istnieje
            if !contactService.canAddContact(id: contactData.id) {
                currentError = .contactAlreadyExists
                return
            }
            
            // Wszystko OK - pokaż confirmation
            showSuccessMessage("Znaleziono kontakt: \(contactData.nickname)")
            
        case .failure(let error):
            currentError = .scanningFailed(error)
        }
    }
    
    /// Resetuje wynik skanowania
    func resetScanResult() {
        scanResult = nil
        lastScannedCode = nil
    }
    
    // MARK: - Contact Management
    
    /// Dodaje kontakt z zeskanowanego QR
    func addContactFromQR() {
        guard let contactData = scannedContactData else { return }
        
        isAddingContact = true
        
        Task {
            do {
                try await qrService.addContactFromQR(contactData)
                
                await MainActor.run {
                    isAddingContact = false
                    resetScanResult()
                    showSuccessMessage("Kontakt \(contactData.nickname) został dodany!")
                    
                    // Wróć do poprzedniego ekranu
                    coordinator.hideQRScanner()
                }
                
            } catch {
                await MainActor.run {
                    isAddingContact = false
                    currentError = .contactAddFailed(error)
                }
            }
        }
    }
    
    /// Anuluje dodawanie kontaktu
    func cancelAddContact() {
        resetScanResult()
        
        // Wznów skanowanie
        if !isScannerActive {
            startScanning()
        }
    }
    
    // MARK: - Share & Export
    
    /// Udostępnia QR kod
    func shareQRCode() {
        guard let qrImage = userQRCode else { return }
        
        // Stwórz share sheet z obrazem
        let activityVC = UIActivityViewController(
            activityItems: [qrImage],
            applicationActivities: nil
        )
        
        // Prezentuj przez coordinator
        // TODO: Implement share sheet presentation
    }
    
    /// Zapisuje QR kod do galerii
    func saveQRCodeToGallery() {
        guard let qrImage = userQRCode else { return }
        
        UIImageWriteToSavedPhotosAlbum(qrImage, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            currentError = .saveToGalleryFailed(error)
        } else {
            showSuccessMessage("QR kod zapisany do galerii")
        }
    }
    
    /// Eksportuje QR jako Data
    func exportQRCode(format: QRExportFormat = .png) -> Data? {
        guard let qrImage = userQRCode else { return nil }
        return qrService.exportQRCode(qrImage, format: format)
    }
    
    // MARK: - Error Handling
    
    /// Czyści błąd
    func clearError() {
        currentError = nil
    }
    
    /// Ponawia ostatnią akcję
    func retryLastAction() {
        clearError()
        
        if isDisplayMode {
            regenerateQRCode()
        } else {
            startScanning()
        }
    }
    
    /// Otwiera ustawienia aplikacji
    func openAppSettings() {
        qrService.openCameraSettings()
    }
    
    /// Pokazuje success message
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        shouldShowSuccessMessage = true
        
        // Auto-hide po 2 sekundach
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.shouldShowSuccessMessage = false
        }
    }
    
    /// Ukrywa success message
    func hideSuccessMessage() {
        shouldShowSuccessMessage = false
    }
    
    // MARK: - Navigation
    
    /// Zamyka QR screen
    func closeQRScreen() {
        stopScanning()
        resetScanResult()
        
        if isDisplayMode {
            coordinator.hideQRDisplay()
        } else {
            coordinator.hideQRScanner()
        }
    }
    
    /// Przełącza między trybami
    func switchMode() {
        if isDisplayMode {
            // Przełącz na scanner
            exitDisplayMode()
            coordinator.showQRScanner()
        } else {
            // Przełącz na display
            stopScanning()
            coordinator.showQRDisplay()
        }
    }
    
    // MARK: - Lifecycle
    
    /// Wywoływane gdy view się pojawia
    func onAppear(displayMode: Bool) {
        isDisplayMode = displayMode
        
        if displayMode {
            loadUserQRCode()
        } else {
            checkCameraPermission()
            
            if cameraPermissionStatus == .authorized {
                startScanning()
            }
        }
    }
    
    /// Wywoływane gdy view znika
    func onDisappear() {
        stopScanning()
        resetScanResult()
        hideSuccessMessage()
    }
    
    // MARK: - Private Methods
    
    /// Konfiguruje obserwatorów
    private func setupObservers() {
        // Obserwuj wyniki skanowania QR
        qrService.qrCodeScannedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.handleScanResult(result)
            }
            .store(in: &cancellables)
        
        // Obserwuj błędy skanowania
        qrService.scanningErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.currentError = .scanningFailed(error)
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
    
    /// Pobiera ID obecnego użytkownika
    private func getCurrentUserID() -> String {
        // W przyszłości z UserService/SettingsService
        return "current-user-id"
    }
}

// MARK: - QR Display Style

/// Style wyświetlania QR kodu
enum QRDisplayStyle: CaseIterable {
    case standard
    case dark
    case colorful
    case minimal
    
    var displayName: String {
        switch self {
        case .standard:
            return "Standardowy"
        case .dark:
            return "Ciemny"
        case .colorful:
            return "Kolorowy"
        case .minimal:
            return "Minimalny"
        }
    }
    
    var size: CGSize {
        switch self {
        case .standard, .dark, .colorful:
            return CGSize(width: 300, height: 300)
        case .minimal:
            return CGSize(width: 200, height: 200)
        }
    }
    
    var foregroundColor: UIColor {
        switch self {
        case .standard, .minimal:
            return .black
        case .dark:
            return .white
        case .colorful:
            return UIColor(AirLinkColors.primary)
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .standard, .minimal:
            return .white
        case .dark:
            return .black
        case .colorful:
            return .white
        }
    }
}

// MARK: - QR Error

enum QRError: LocalizedError, Identifiable {
    case qrGenerationFailed(Error)
    case scannerStartFailed(Error)
    case scanningFailed(QRServiceError)
    case contactAddFailed(Error)
    case cameraPermissionDenied
    case cannotAddSelf
    case contactAlreadyExists
    case saveToGalleryFailed(Error)
    case exportFailed
    
    var id: String {
        switch self {
        case .qrGenerationFailed:
            return "qr-generation-failed"
        case .scannerStartFailed:
            return "scanner-start-failed"
        case .scanningFailed:
            return "scanning-failed"
        case .contactAddFailed:
            return "contact-add-failed"
        case .cameraPermissionDenied:
            return "camera-permission-denied"
        case .cannotAddSelf:
            return "cannot-add-self"
        case .contactAlreadyExists:
            return "contact-already-exists"
        case .saveToGalleryFailed:
            return "save-to-gallery-failed"
        case .exportFailed:
            return "export-failed"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .qrGenerationFailed:
            return "Nie udało się wygenerować kodu QR"
        case .scannerStartFailed:
            return "Nie udało się uruchomić skanera"
        case .scanningFailed(let qrError):
            return qrError.errorDescription
        case .contactAddFailed:
            return "Nie udało się dodać kontaktu"
        case .cameraPermissionDenied:
            return "Brak dostępu do kamery"
        case .cannotAddSelf:
            return "Nie możesz dodać siebie jako kontakt"
        case .contactAlreadyExists:
            return "Kontakt już istnieje"
        case .saveToGalleryFailed:
            return "Nie udało się zapisać do galerii"
        case .exportFailed:
            return "Nie udało się wyeksportować QR kodu"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .qrGenerationFailed, .scannerStartFailed:
            return "Spróbuj ponownie za chwilę"
        case .scanningFailed:
            return "Sprawdź oświetlenie i spróbuj ponownie"
        case .contactAddFailed:
            return "Sprawdź połączenie internetowe"
        case .cameraPermissionDenied:
            return "Przejdź do Ustawień i włącz dostęp do kamery"
        case .cannotAddSelf:
            return "Zeskanuj kod QR innej osoby"
        case .contactAlreadyExists:
            return "Ten kontakt już znajduje się na Twojej liście"
        case .saveToGalleryFailed:
            return "Sprawdź uprawnienia do galerii"
        case .exportFailed:
            return "Spróbuj ponownie"
        }
    }
}

// MARK: - Extensions

extension QRViewModel {
    
    /// Sprawdza czy można przełączyć flash
    var canToggleFlash: Bool {
        isScannerActive && shouldShowFlashToggle
    }
    
    /// Sprawdza czy można zapisać QR do galerii
    var canSaveToGallery: Bool {
        userQRCode != nil
    }
    
    /// Sprawdza czy można udostępnić QR
    var canShareQR: Bool {
        userQRCode != nil
    }
    
    /// Formatuje status kamery
    var cameraStatusText: String {
        switch cameraPermissionStatus {
        case .notDetermined:
            return "Dotknij aby umożliwić dostęp do kamery"
        case .restricted:
            return "Dostęp do kamery ograniczony"
        case .denied:
            return "Dostęp do kamery odmówiony"
        case .authorized:
            return "Kamera gotowa"
        @unknown default:
            return "Nieznany status kamery"
        }
    }
    
    /// Zwraca ikonę dla statusu kamery
    var cameraStatusIcon: String {
        switch cameraPermissionStatus {
        case .notDetermined:
            return "camera"
        case .restricted, .denied:
            return "camera.slash"
        case .authorized:
            return "camera.viewfinder"
        @unknown default:
            return "camera.fill"
        }
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension QRViewModel {
    
    /// Tworzy mock view model dla preview
    static func createMockViewModel(displayMode: Bool = false) -> QRViewModel {
        let mockQRService = QRService.createMockService()
        let mockContactService = ContactService.createMockService()
        let mockCoordinator = NavigationCoordinator.createMockCoordinator()
        
        let viewModel = QRViewModel(
            qrService: mockQRService,
            contactService: mockContactService,
            coordinator: mockCoordinator
        )
        
        viewModel.isDisplayMode = displayMode
        viewModel.cameraPermissionStatus = .authorized
        
        if displayMode {
            viewModel.userQRCode = mockQRService.generateSampleQRCode()
        }
        
        return viewModel
    }
    
    /// Symuluje różne stany
    func simulateState(_ state: MockQRState) {
        switch state {
        case .displayingQR:
            isDisplayMode = true
            userQRCode = qrService.generateSampleQRCode()
            
        case .scanningActive:
            isDisplayMode = false
            isScannerActive = true
            cameraPermissionStatus = .authorized
            
        case .scanSuccess:
            scanResult = .success(ContactQRData(
                id: "sample-contact",
                nickname: "Anna Kowalska",
                hasAvatar: true,
                version: 1
            ))
            
        case .scanError:
            scanResult = .failure(.invalidQRFormat)
            
        case .permissionDenied:
            cameraPermissionStatus = .denied
            currentError = .cameraPermissionDenied
            
        case .generating:
            isGeneratingQR = true
            
        case .addingContact:
            isAddingContact = true
            
        case .withSuccess:
            showSuccessMessage("QR kod wygenerowany")
        }
    }
}

enum MockQRState {
    case displayingQR
    case scanningActive
    case scanSuccess
    case scanError
    case permissionDenied
    case generating
    case addingContact
    case withSuccess
}
#endif
