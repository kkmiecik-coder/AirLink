//
//  QRViewModel.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import UIKit
import AVFoundation
import Combine

// MARK: - QRViewModel

/// ViewModel zarządzający operacjami QR - skanowaniem i wyświetlaniem
/// Koordynuje działanie QRService z interfejsem użytkownika
@Observable
final class QRViewModel {
    
    // MARK: - Dependencies
    
    private let qrService: QRService
    private let contactService: ContactService
    private let coordinator: NavigationCoordinator
    
    // MARK: - QR Display State
    
    /// Aktualnie wyświetlany kod QR użytkownika
    private(set) var userQRCode: UIImage?
    
    /// Czy kod QR jest w trakcie generowania
    private(set) var isGeneratingQR = false
    
    /// Błąd generowania kodu QR
    private(set) var qrGenerationError: QRError?
    
    // MARK: - QR Scanning State
    
    /// Czy skanowanie jest aktywne
    private(set) var isScanningActive = false
    
    /// Status uprawnień do kamery
    private(set) var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    /// Czy kamera jest dostępna
    private(set) var isCameraAvailable = false
    
    /// Czy flash jest włączony
    var isFlashEnabled = false
    
    /// Wynik ostatniego skanowania
    private(set) var lastScanResult: QRScanResult?
    
    /// Czy pokazywać wynik skanowania
    var shouldShowScanResult: Bool {
        lastScanResult != nil
    }
    
    // MARK: - Contact Management State
    
    /// Dane kontaktu do dodania (z QR)
    private(set) var pendingContactData: ContactQRData?
    
    /// Czy pokazywać sheet dodawania kontaktu
    var shouldShowAddContactSheet: Bool {
        pendingContactData != nil
    }
    
    /// Czy trwa dodawanie kontaktu
    private(set) var isAddingContact = false
    
    // MARK: - Error State
    
    /// Aktualny błąd QR
    private(set) var currentError: QRError?
    
    /// Czy pokazywać alert błędu
    var shouldShowError: Bool {
        currentError != nil
    }
    
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
    
    // MARK: - QR Display Methods
    
    /// Ładuje kod QR użytkownika
    func loadUserQRCode() {
        userQRCode = qrService.currentUserQRCode
        
        if userQRCode == nil {
            generateUserQRCode()
        }
    }
    
    /// Generuje nowy kod QR użytkownika
    func generateUserQRCode() {
        isGeneratingQR = true
        qrGenerationError = nil
        
        Task {
            do {
                await qrService.generateUserQRCodeAsync()
                
                await MainActor.run {
                    userQRCode = qrService.currentUserQRCode
                    isGeneratingQR = false
                }
            } catch {
                await MainActor.run {
                    qrGenerationError = .generationFailed(error)
                    isGeneratingQR = false
                }
            }
        }
    }
    
    /// Regeneruje kod QR użytkownika
    func regenerateUserQRCode() {
        userQRCode = nil
        generateUserQRCode()
    }
    
    /// Udostępnia kod QR
    func shareQRCode() {
        guard let qrImage = userQRCode else { return }
        
        coordinator.shareItems([qrImage])
    }
    
    /// Zapisuje kod QR do galerii zdjęć
    func saveQRCodeToPhotos() {
        guard let qrImage = userQRCode else { return }
        
        UIImageWriteToSavedPhotosAlbum(qrImage, nil, nil, nil)
        
        // TODO: Show success feedback
        HapticManager.shared.impact(.medium)
    }
    
    // MARK: - QR Scanning Methods
    
    /// Rozpoczyna skanowanie QR
    func startScanning() {
        guard cameraPermissionStatus == .authorized else {
            requestCameraPermission()
            return
        }
        
        isScanningActive = true
        qrService.startScanning()
    }
    
    /// Zatrzymuje skanowanie QR
    func stopScanning() {
        isScanningActive = false
        qrService.stopScanning()
    }
    
    /// Sprawdza uprawnienia do kamery
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        isCameraAvailable = qrService.isCameraAvailable
    }
    
    /// Żąda uprawnień do kamery
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionStatus = granted ? .authorized : .denied
                
                if granted {
                    self?.startScanning()
                } else {
                    self?.currentError = .cameraPermissionDenied
                }
            }
        }
    }
    
    /// Otwiera ustawienia aplikacji
    func openAppSettings() {
        qrService.openCameraSettings()
    }
    
    /// Przełącza flash
    func toggleFlash() {
        isFlashEnabled.toggle()
        // Flash jest obsługiwany przez CameraPreview
    }
    
    // MARK: - Scan Result Handling
    
    /// Obsługuje wynik skanowania QR
    func handleScanResult(_ result: QRScanResult) {
        lastScanResult = result
        
        switch result {
        case .success(let contactData):
            // Sprawdź czy kontakt już istnieje
            if contactService.findContact(by: contactData.id) != nil {
                lastScanResult = .contactExists
            } else {
                pendingContactData = contactData
            }
            
            // Haptic feedback
            HapticManager.shared.notification(.success)
            
        case .invalidFormat, .contactExists:
            // Haptic feedback dla błędu
            HapticManager.shared.notification(.error)
            
        case .error:
            // Haptic feedback dla błędu
            HapticManager.shared.notification(.error)
        }
        
        // Zatrzymaj skanowanie tymczasowo
        stopScanning()
    }
    
    /// Czyści wynik skanowania
    func clearScanResult() {
        lastScanResult = nil
        
        // Wznów skanowanie po krótkiej przerwie
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.isScanningActive == true {
                self?.startScanning()
            }
        }
    }
    
    // MARK: - Contact Management
    
    /// Dodaje kontakt z danych QR
    func addContactFromQR() {
        guard let contactData = pendingContactData else { return }
        
        isAddingContact = true
        
        Task {
            do {
                let contact = try await contactService.addContact(from: contactData)
                
                await MainActor.run {
                    isAddingContact = false
                    pendingContactData = nil
                    
                    // Pokaż szczegóły dodanego kontaktu
                    coordinator.openContactDetails(contact)
                }
                
                // Success haptic
                HapticManager.shared.notification(.success)
                
            } catch {
                await MainActor.run {
                    isAddingContact = false
                    currentError = .contactAddFailed(error)
                }
                
                // Error haptic
                HapticManager.shared.notification(.error)
            }
        }
    }
    
    /// Anuluje dodawanie kontaktu
    func cancelAddingContact() {
        pendingContactData = nil
        clearScanResult()
    }
    
    // MARK: - Error Handling
    
    /// Czyści błąd
    func clearError() {
        currentError = nil
        qrGenerationError = nil
    }
    
    /// Ponawia ostatnią akcję
    func retryLastAction() {
        clearError()
        
        if qrGenerationError != nil {
            generateUserQRCode()
        }
    }
    
    // MARK: - Lifecycle
    
    /// Wywoływane gdy view się pojawia
    func onAppear() {
        checkCameraPermission()
        loadUserQRCode()
    }
    
    /// Wywoływane gdy view znika
    func onDisappear() {
        stopScanning()
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
}

// MARK: - QR Error

enum QRError: LocalizedError {
    case generationFailed(Error)
    case scanningFailed(QRServiceError)
    case cameraPermissionDenied
    case cameraNotAvailable
    case contactAddFailed(Error)
    case invalidQRData
    
    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Nie udało się wygenerować kodu QR"
        case .scanningFailed:
            return "Błąd skanowania kodu QR"
        case .cameraPermissionDenied:
            return "Brak dostępu do kamery"
        case .cameraNotAvailable:
            return "Kamera nie jest dostępna"
        case .contactAddFailed:
            return "Nie udało się dodać kontaktu"
        case .invalidQRData:
            return "Nieprawidłowe dane w kodzie QR"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .generationFailed:
            return "Spróbuj ponownie lub zrestartuj aplikację"
        case .scanningFailed:
            return "Sprawdź oświetlenie i spróbuj ponownie"
        case .cameraPermissionDenied:
            return "Przejdź do Ustawień i włącz dostęp do kamery"
        case .cameraNotAvailable:
            return "Sprawdź czy inna aplikacja nie używa kamery"
        case .contactAddFailed:
            return "Sprawdź połączenie i spróbuj ponownie"
        case .invalidQRData:
            return "Upewnij się że skanujesz kod QR z AirLink"
        }
    }
}

// MARK: - Extensions

extension QRService {
    
    /// Asynchroniczna wersja generowania QR kodu
    func generateUserQRCodeAsync() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // Symulacja asynchronicznego generowania
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateUserQRCode()
                
                if self.currentUserQRCode != nil {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: QRServiceError.generationFailed)
                }
            }
        }
    }
}

extension NavigationCoordinator {
    
    /// Udostępnia elementy
    func shareItems(_ items: [Any]) {
        // TODO: Implement sharing functionality
        print("Sharing items: \(items)")
    }
    
    /// Otwiera szczegóły kontaktu
    func openContactDetails(_ contact: Contact) {
        // TODO: Implement contact details navigation
        print("Opening contact details for: \(contact.nickname)")
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension QRViewModel {
    
    /// Tworzy mock view model dla preview
    static func createMockViewModel() -> QRViewModel {
        let mockQRService = QRService.createMockService()
        let mockContactService = ContactService.createMockService()
        let mockCoordinator = NavigationCoordinator.createMockCoordinator()
        
        let viewModel = QRViewModel(
            qrService: mockQRService,
            contactService: mockContactService,
            coordinator: mockCoordinator
        )
        
        // Ustaw przykładowe dane
        viewModel.userQRCode = UIImage(systemName: "qrcode")
        viewModel.cameraPermissionStatus = .authorized
        viewModel.isCameraAvailable = true
        
        return viewModel
    }
    
    /// Symuluje różne stany
    func simulateState(_ state: MockQRState) {
        switch state {
        case .generatingQR:
            isGeneratingQR = true
            userQRCode = nil
            
        case .scanningActive:
            isScanningActive = true
            
        case .scanResult(let result):
            lastScanResult = result
            
        case .pendingContact(let contactData):
            pendingContactData = contactData
            
        case .cameraPermissionDenied:
            cameraPermissionStatus = .denied
            currentError = .cameraPermissionDenied
            
        case .addingContact:
            isAddingContact = true
            
        case .withError(let error):
            currentError = error
        }
    }
}

enum MockQRState {
    case generatingQR
    case scanningActive
    case scanResult(QRScanResult)
    case pendingContact(ContactQRData)
    case cameraPermissionDenied
    case addingContact
    case withError(QRError)
}
#endif
