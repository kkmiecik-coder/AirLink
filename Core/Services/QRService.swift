//
//  QRService.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import UIKit
import CoreImage
import AVFoundation
import Combine

// MARK: - QRService

/// Serwis odpowiedzialny za generowanie i skanowanie kodów QR w AirLink
/// Obsługuje kodowanie/dekodowanie danych kontaktów oraz camera scanning
@Observable
final class QRService: NSObject {
    
    // MARK: - Properties
    
    private let contactService: ContactService
    private let connectivityService: ConnectivityService
    
    /// Czy skanowanie jest aktywne
    private(set) var isScanningActive = false
    
    /// Czy kamera jest dostępna
    private(set) var isCameraAvailable = false
    
    /// Status uprawnień do kamery
    private(set) var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    /// Aktualnie wygenerowany QR kod użytkownika
    private(set) var currentUserQRCode: UIImage?
    
    /// Session kamery do skanowania
    private var captureSession: AVCaptureSession?
    
    /// Input kamery
    private var cameraInput: AVCaptureDeviceInput?
    
    /// Output do analizy QR
    private var metadataOutput: AVCaptureMetadataOutput?
    
    // MARK: - Publishers
    
    private let qrCodeScannedSubject = PassthroughSubject<QRScanResult, Never>()
    var qrCodeScannedPublisher: AnyPublisher<QRScanResult, Never> {
        qrCodeScannedSubject.eraseToAnyPublisher()
    }
    
    private let scanningErrorSubject = PassthroughSubject<QRServiceError, Never>()
    var scanningErrorPublisher: AnyPublisher<QRServiceError, Never> {
        scanningErrorSubject.eraseToAnyPublisher()
    }
    
    private let cameraPermissionUpdatedSubject = PassthroughSubject<AVAuthorizationStatus, Never>()
    var cameraPermissionUpdatedPublisher: AnyPublisher<AVAuthorizationStatus, Never> {
        cameraPermissionUpdatedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    init(contactService: ContactService, connectivityService: ConnectivityService) {
        self.contactService = contactService
        self.connectivityService = connectivityService
        
        super.init()
        
        checkCameraAvailability()
        checkCameraPermission()
        generateUserQRCode()
    }
    
    deinit {
        stopScanning()
    }
    
    // MARK: - QR Code Generation
    
    /// Generuje kod QR dla obecnego użytkownika
    func generateUserQRCode() {
        do {
            let qrData = try createUserQRData()
            currentUserQRCode = try generateQRCodeImage(from: qrData)
            
            print("📱 Generated user QR code")
        } catch {
            print("❌ Failed to generate user QR code: \(error)")
        }
    }
    
    /// Tworzy dane QR dla użytkownika
    private func createUserQRData() throws -> Data {
        let userProfile = getUserProfile() // Z SettingsService w przyszłości
        
        let qrData = ContactQRData(
            id: connectivityService.localPeerID.displayName,
            nickname: userProfile.nickname,
            hasAvatar: userProfile.avatarData != nil,
            version: 1
        )
        
        return try JSONEncoder().encode(qrData)
    }
    
    /// Generuje obraz QR kodu z danych
    func generateQRCodeImage(from data: Data, size: CGSize = CGSize(width: 300, height: 300)) throws -> UIImage {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRServiceError.qrGenerationFailed
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter.outputImage else {
            throw QRServiceError.qrGenerationFailed
        }
        
        // Skaluj do żądanego rozmiaru
        let scaleX = size.width / ciImage.extent.size.width
        let scaleY = size.height / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Konwertuj na UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw QRServiceError.qrGenerationFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generuje kod QR z custom kolorami
    func generateStyledQRCode(
        from data: Data,
        size: CGSize = CGSize(width: 300, height: 300),
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white
    ) throws -> UIImage {
        let baseImage = try generateQRCodeImage(from: data, size: size)
        
        // Zastosuj kolory
        guard let colorFilter = CIFilter(name: "CIFalseColor") else {
            return baseImage
        }
        
        colorFilter.setValue(CIImage(image: baseImage), forKey: "inputImage")
        colorFilter.setValue(CIColor(color: foregroundColor), forKey: "inputColor0")
        colorFilter.setValue(CIColor(color: backgroundColor), forKey: "inputColor1")
        
        guard let outputImage = colorFilter.outputImage else {
            return baseImage
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return baseImage
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - QR Code Scanning
    
    /// Żąda uprawnień do kamery
    func requestCameraPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        
        DispatchQueue.main.async { [weak self] in
            self?.cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
            self?.cameraPermissionUpdatedSubject.send(self?.cameraPermissionStatus ?? .denied)
        }
        
        return status
    }
    
    /// Rozpoczyna skanowanie QR kodów
    func startScanning() throws -> AVCaptureVideoPreviewLayer {
        guard !isScanningActive else {
            throw QRServiceError.scanningAlreadyActive
        }
        
        guard isCameraAvailable else {
            throw QRServiceError.cameraNotAvailable
        }
        
        guard cameraPermissionStatus == .authorized else {
            throw QRServiceError.cameraPermissionDenied
        }
        
        let session = AVCaptureSession()
        
        // Konfiguruj input
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw QRServiceError.cameraNotAvailable
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        
        guard session.canAddInput(input) else {
            throw QRServiceError.cameraSetupFailed
        }
        
        session.addInput(input)
        self.cameraInput = input
        
        // Konfiguruj output
        let output = AVCaptureMetadataOutput()
        
        guard session.canAddOutput(output) else {
            throw QRServiceError.cameraSetupFailed
        }
        
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]
        self.metadataOutput = output
        
        // Uruchom session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        
        self.captureSession = session
        self.isScanningActive = true
        
        // Zwróć preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        print("📱 Started QR scanning")
        return previewLayer
    }
    
    /// Zatrzymuje skanowanie QR kodów
    func stopScanning() {
        guard isScanningActive else { return }
        
        captureSession?.stopRunning()
        captureSession = nil
        cameraInput = nil
        metadataOutput = nil
        isScanningActive = false
        
        print("📱 Stopped QR scanning")
    }
    
    /// Parsuje zeskanowany QR kod
    func parseQRCode(_ code: String) -> QRScanResult {
        do {
            // Spróbuj zdekodować jako AirLink contact data
            guard let data = code.data(using: .utf8) else {
                return .failure(.invalidQRFormat)
            }
            
            let contactData = try JSONDecoder().decode(ContactQRData.self, from: data)
            
            // Waliduj dane
            guard isValidContactData(contactData) else {
                return .failure(.invalidContactData)
            }
            
            return .success(contactData)
            
        } catch {
            // Sprawdź czy to może być inny format (URL, tekst, etc.)
            if code.hasPrefix("http") {
                return .failure(.unsupportedFormat)
            }
            
            return .failure(.invalidQRFormat)
        }
    }
    
    /// Waliduje dane kontaktu z QR
    private func isValidContactData(_ data: ContactQRData) -> Bool {
        // Sprawdź wersję
        guard data.version == 1 else { return false }
        
        // Sprawdź czy to nie nasz własny QR
        guard data.id != connectivityService.localPeerID.displayName else { return false }
        
        // Sprawdź długość nickname
        guard !data.nickname.isEmpty && data.nickname.count <= AppConstants.Limits.maxNicknameLength else {
            return false
        }
        
        return true
    }
    
    // MARK: - Contact Adding from QR
    
    /// Dodaje kontakt z danych QR
    func addContactFromQR(_ contactData: ContactQRData) async throws {
        // Sprawdź czy kontakt już istnieje
        if contactService.canAddContact(id: contactData.id) {
            // Dodaj kontakt bez avatara (zostanie pobrany później)
            try contactService.addContact(
                id: contactData.id,
                nickname: contactData.nickname,
                avatarData: nil
            )
            
            // Jeśli kontakt ma avatar, spróbuj go pobrać
            if contactData.hasAvatar {
                await fetchContactAvatar(contactData.id)
            }
            
            print("✅ Added contact from QR: \(contactData.nickname)")
        } else {
            // Kontakt już istnieje - zaktualizuj dane
            try contactService.updateContactNickname(
                contactService.findContact(by: contactData.id)!,
                nickname: contactData.nickname
            )
            
            print("ℹ️ Updated existing contact: \(contactData.nickname)")
        }
    }
    
    /// Pobiera avatar kontaktu po dodaniu z QR
    private func fetchContactAvatar(_ contactID: String) async {
        do {
            // Czekaj aż kontakt będzie online
            let timeoutDate = Date().addingTimeInterval(30) // 30 sekund timeout
            
            while Date() < timeoutDate {
                if contactService.isContactOnline(id: contactID) {
                    // Kontakt online - pobierz avatar
                    if let avatarData = try await contactService.fetchContactAvatar(contactID: contactID) {
                        try contactService.updateContactAvatar(
                            contactService.findContact(by: contactID)!,
                            avatarData: avatarData
                        )
                        print("📷 Fetched avatar for contact: \(contactID)")
                    }
                    return
                }
                
                // Czekaj 1 sekundę przed kolejną próbą
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            print("⏰ Timeout waiting for contact to come online: \(contactID)")
            
        } catch {
            print("❌ Failed to fetch avatar for contact \(contactID): \(error)")
        }
    }
    
    // MARK: - Batch QR Operations
    
    /// Generuje QR kody dla wielu kontaktów (do udostępniania)
    func generateContactQRCodes(_ contacts: [Contact]) -> [String: UIImage] {
        var qrCodes: [String: UIImage] = [:]
        
        for contact in contacts {
            do {
                let contactData = ContactQRData(
                    id: contact.id,
                    nickname: contact.nickname,
                    hasAvatar: contact.hasCustomAvatar,
                    version: 1
                )
                
                let data = try JSONEncoder().encode(contactData)
                let qrImage = try generateQRCodeImage(from: data)
                qrCodes[contact.id] = qrImage
                
            } catch {
                print("❌ Failed to generate QR for contact \(contact.nickname): \(error)")
            }
        }
        
        return qrCodes
    }
    
    /// Eksportuje QR kod jako image data
    func exportQRCode(_ image: UIImage, format: QRExportFormat = .png) -> Data? {
        switch format {
        case .png:
            return image.pngData()
        case .jpeg(let quality):
            return image.jpegData(compressionQuality: quality)
        }
    }
    
    // MARK: - Camera Management
    
    private func checkCameraAvailability() {
        isCameraAvailable = AVCaptureDevice.default(for: .video) != nil
    }
    
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Sprawdza czy kamera może skupiać
    func isFocusSupported() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.isFocusModeSupported(.autoFocus)
    }
    
    /// Skupia kamerę w punkcie
    func focusCamera(at point: CGPoint) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.isFocusModeSupported(.autoFocus),
              device.isFocusPointOfInterestSupported else { return }
        
        do {
            try device.lockForConfiguration()
            device.focusMode = .autoFocus
            device.focusPointOfInterest = point
            device.unlockForConfiguration()
        } catch {
            print("❌ Failed to focus camera: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    private func getUserProfile() -> UserProfile {
        // W przyszłości będzie pobierać z SettingsService
        return UserProfile.current
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRService: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let code = metadataObject.stringValue else { return }
        
        // Parsuj i wyślij rezultat
        let result = parseQRCode(code)
        qrCodeScannedSubject.send(result)
        
        // Tymczasowo zatrzymaj skanowanie po udanym skanowaniu
        if case .success = result {
            stopScanning()
        }
    }
}

// MARK: - Data Models

/// Dane kontaktu w QR kodzie
struct ContactQRData: Codable {
    let id: String
    let nickname: String
    let hasAvatar: Bool
    let version: Int
}

/// Rezultat skanowania QR
enum QRScanResult {
    case success(ContactQRData)
    case failure(QRServiceError)
}

/// Format eksportu QR
enum QRExportFormat {
    case png
    case jpeg(quality: CGFloat)
}

// MARK: - QR Service Errors

enum QRServiceError: LocalizedError {
    case qrGenerationFailed
    case cameraNotAvailable
    case cameraPermissionDenied
    case cameraSetupFailed
    case scanningAlreadyActive
    case invalidQRFormat
    case invalidContactData
    case unsupportedFormat
    case contactAlreadyExists
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .qrGenerationFailed:
            return "Nie udało się wygenerować kodu QR"
        case .cameraNotAvailable:
            return "Kamera nie jest dostępna"
        case .cameraPermissionDenied:
            return "Brak uprawnień do kamery"
        case .cameraSetupFailed:
            return "Nie udało się skonfigurować kamery"
        case .scanningAlreadyActive:
            return "Skanowanie jest już aktywne"
        case .invalidQRFormat:
            return "Nieprawidłowy format kodu QR"
        case .invalidContactData:
            return "Nieprawidłowe dane kontaktu"
        case .unsupportedFormat:
            return "Nieobsługiwany format kodu QR"
        case .contactAlreadyExists:
            return "Kontakt już istnieje"
        case .encodingFailed:
            return "Błąd kodowania danych"
        }
    }
}

// MARK: - Extensions

extension QRService {
    
    /// Sprawdza czy można rozpocząć skanowanie
    func canStartScanning() -> Bool {
        return isCameraAvailable &&
               cameraPermissionStatus == .authorized &&
               !isScanningActive
    }
    
    /// Zwraca status uprawnień jako tekst
    func getCameraPermissionStatusText() -> String {
        switch cameraPermissionStatus {
        case .notDetermined:
            return "Nie określono"
        case .restricted:
            return "Ograniczone"
        case .denied:
            return "Odmówiono"
        case .authorized:
            return "Udzielono"
        @unknown default:
            return "Nieznany"
        }
    }
    
    /// Otwiera ustawienia aplikacji dla uprawnień kamery
    func openCameraSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension QRService {
    
    /// Tworzy mock service dla preview i testów
    static func createMockService() -> QRService {
        let mockContacts = ContactService.createMockService()
        let mockConnectivity = MockConnectivityService()
        
        let service = QRService(
            contactService: mockContacts,
            connectivityService: mockConnectivity
        )
        
        return service
    }
    
    /// Generuje przykładowy QR kod
    func generateSampleQRCode() -> UIImage? {
        let sampleData = ContactQRData(
            id: "sample-user-123",
            nickname: "Jan Kowalski",
            hasAvatar: true,
            version: 1
        )
        
        do {
            let data = try JSONEncoder().encode(sampleData)
            return try generateQRCodeImage(from: data)
        } catch {
            return nil
        }
    }
    
    /// Symuluje skanowanie QR kodu
    func simulateQRScan(_ contactData: ContactQRData) {
        let result = QRScanResult.success(contactData)
        qrCodeScannedSubject.send(result)
    }
}
#endif
