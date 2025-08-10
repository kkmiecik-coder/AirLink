//
//  QRScannerView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI
import AVFoundation

// MARK: - QRScannerView

/// Widok skanera kodów QR do dodawania kontaktów
/// Używa kamery do skanowania i dekodowania kodów QR
struct QRScannerView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(QRService.self) private var qrService
    @Environment(ContactService.self) private var contactService
    @Environment(NavigationCoordinator.self) private var coordinator
    
    // MARK: - State
    
    @State private var isScanning = false
    @State private var scanResult: QRScanResult?
    @State private var showingResult = false
    @State private var showingPermissionDenied = false
    @State private var flashEnabled = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                if qrService.cameraPermissionStatus == .authorized {
                    cameraPreview
                } else {
                    permissionView
                }
                
                // Overlay UI
                overlayUI
            }
            .navigationTitle("Skanuj kod QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    flashButton
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            checkPermissionsAndStartScanning()
        }
        .onDisappear {
            stopScanning()
        }
        .sheet(isPresented: $showingResult) {
            if let result = scanResult {
                QRScanResultView(
                    result: result,
                    onDismiss: { handleScanResultDismiss() },
                    onAddContact: { handleAddContact() }
                )
            }
        }
        .alert("Brak dostępu do kamery", isPresented: $showingPermissionDenied) {
            Button("Ustawienia") {
                openSettings()
            }
            Button("Anuluj", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("AirLink potrzebuje dostępu do kamery, żeby skanować kody QR. Przejdź do Ustawień i włącz dostęp do kamery.")
        }
    }
    
    // MARK: - Camera Preview
    
    private var cameraPreview: some View {
        CameraPreviewView(
            isScanning: $isScanning,
            flashEnabled: $flashEnabled,
            onQRCodeDetected: handleQRCodeDetected
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Permission View
    
    private var permissionView: some View {
        VStack(spacing: AppTheme.current.spacing.xl) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AirLinkColors.textSecondary)
            
            VStack(spacing: AppTheme.current.spacing.sm) {
                Text("Dostęp do kamery")
                    .font(AppTheme.current.typography.title2)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text("AirLink potrzebuje dostępu do kamery, żeby skanować kody QR i dodawać kontakty")
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Włącz dostęp do kamery") {
                requestCameraPermission()
            }
            .buttonStyle(.borderedProminent)
            .tint(AirLinkColors.primary)
        }
        .padding(.horizontal, AppTheme.current.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AirLinkColors.background)
    }
    
    // MARK: - Overlay UI
    
    private var overlayUI: some View {
        VStack {
            Spacer()
            
            // Scanning frame
            scanningFrame
            
            Spacer()
            
            // Instructions
            instructionsPanel
        }
    }
    
    // MARK: - Scanning Frame
    
    private var scanningFrame: some View {
        ZStack {
            // Dimmed background
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .ignoresSafeArea()
            
            // Scanning area
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Clear scanning area
                    Rectangle()
                        .frame(width: 250, height: 250)
                        .blendMode(.destinationOut)
                        .overlay(
                            // Corner brackets
                            cornerBrackets
                        )
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .compositingGroup()
    }
    
    // MARK: - Corner Brackets
    
    private var cornerBrackets: some View {
        ZStack {
            // Top-left
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 30, height: 6)
                    Spacer()
                }
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 6, height: 30)
                    Spacer()
                }
                Spacer()
            }
            
            // Top-right
            VStack {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 30, height: 6)
                }
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 6, height: 30)
                }
                Spacer()
            }
            
            // Bottom-left
            VStack {
                Spacer()
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 6, height: 30)
                    Spacer()
                }
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 30, height: 6)
                    Spacer()
                }
            }
            
            // Bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 6, height: 30)
                }
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 30, height: 6)
                }
            }
        }
        .scaleEffect(isScanning ? 1.02 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: isScanning
        )
    }
    
    // MARK: - Instructions Panel
    
    private var instructionsPanel: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            Text("Umieść kod QR w ramce")
                .font(AppTheme.current.typography.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Kod zostanie automatycznie zeskanowany gdy znajdzie się w polu widzenia kamery")
                .font(AppTheme.current.typography.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(.horizontal, AppTheme.current.spacing.xl)
        .padding(.bottom, AppTheme.current.spacing.xl)
    }
    
    // MARK: - Flash Button
    
    private var flashButton: some View {
        Button(action: { flashEnabled.toggle() }) {
            Image(systemName: flashEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                )
        }
    }
    
    // MARK: - Actions
    
    private func checkPermissionsAndStartScanning() {
        switch qrService.cameraPermissionStatus {
        case .authorized:
            startScanning()
        case .denied, .restricted:
            showingPermissionDenied = true
        case .notDetermined:
            requestCameraPermission()
        @unknown default:
            requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    startScanning()
                } else {
                    showingPermissionDenied = true
                }
            }
        }
    }
    
    private func startScanning() {
        isScanning = true
        qrService.startScanning()
    }
    
    private func stopScanning() {
        isScanning = false
        qrService.stopScanning()
    }
    
    private func handleQRCodeDetected(_ code: String) {
        guard !showingResult else { return }
        
        // Parse QR code
        let result = qrService.parseQRCode(code)
        scanResult = result
        showingResult = true
        
        // Haptic feedback
        HapticManager.shared.notification(.success)
        
        // Stop scanning temporarily
        isScanning = false
    }
    
    private func handleScanResultDismiss() {
        showingResult = false
        scanResult = nil
        
        // Resume scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isScanning = true
        }
    }
    
    private func handleAddContact() {
        guard let result = scanResult,
              case .success(let contactData) = result else { return }
        
        Task {
            do {
                let contact = try await contactService.addContact(from: contactData)
                
                await MainActor.run {
                    dismiss()
                    coordinator.showContactDetails(contact)
                }
            } catch {
                // Handle error
                print("Failed to add contact: \(error)")
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Camera Preview View

private struct CameraPreviewView: UIViewRepresentable {
    
    @Binding var isScanning: Bool
    @Binding var flashEnabled: Bool
    let onQRCodeDetected: (String) -> Void
    
    func makeUIView(context: Context) -> CameraPreview {
        let preview = CameraPreview()
        preview.delegate = context.coordinator
        return preview
    }
    
    func updateUIView(_ uiView: CameraPreview, context: Context) {
        if isScanning {
            uiView.startSession()
        } else {
            uiView.stopSession()
        }
        
        uiView.setFlashEnabled(flashEnabled)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraPreviewDelegate {
        let parent: CameraPreviewView
        
        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func didDetectQRCode(_ code: String) {
            parent.onQRCodeDetected(code)
        }
    }
}

// MARK: - Camera Preview

private protocol CameraPreviewDelegate: AnyObject {
    func didDetectQRCode(_ code: String)
}

private class CameraPreview: UIView {
    
    weak var delegate: CameraPreviewDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var cameraDevice: AVCaptureDevice?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        cameraDevice = device
        captureSession = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            let output = AVCaptureMetadataOutput()
            
            captureSession?.addInput(input)
            captureSession?.addOutput(output)
            
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.videoGravity = .resizeAspectFill
            
            layer.addSublayer(previewLayer!)
            
        } catch {
            print("Failed to setup camera: \(error)")
        }
    }
    
    func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func stopSession() {
        guard let session = captureSession, session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }
    
    func setFlashEnabled(_ enabled: Bool) {
        guard let device = cameraDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = enabled ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Failed to toggle flash: \(error)")
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraPreview: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        delegate?.didDetectQRCode(stringValue)
    }
}

// MARK: - QR Scan Result View

private struct QRScanResultView: View {
    
    let result: QRScanResult
    let onDismiss: () -> Void
    let onAddContact: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.current.spacing.xl) {
                
                // Result icon
                resultIcon
                
                // Result content
                resultContent
                
                // Actions
                resultActions
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.current.spacing.lg)
            .padding(.top, AppTheme.current.spacing.xl)
            .navigationTitle("Wynik skanowania")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zamknij") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var resultIcon: some View {
        switch result {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AirLinkColors.statusSuccess)
        case .invalidFormat, .contactExists, .error:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AirLinkColors.statusError)
        }
    }
    
    @ViewBuilder
    private var resultContent: some View {
        switch result {
        case .success(let contactData):
            VStack(spacing: AppTheme.current.spacing.md) {
                Text("Znaleziono kontakt!")
                    .font(AppTheme.current.typography.title2)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                VStack(spacing: AppTheme.current.spacing.sm) {
                    AvatarView.text(contactData.nickname, size: .large)
                    
                    Text(contactData.nickname)
                        .font(AppTheme.current.typography.title3)
                        .foregroundColor(AirLinkColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text("AirLink User")
                        .font(AppTheme.current.typography.body)
                        .foregroundColor(AirLinkColors.textSecondary)
                }
            }
            
        case .invalidFormat:
            VStack(spacing: AppTheme.current.spacing.sm) {
                Text("Nieprawidłowy kod QR")
                    .font(AppTheme.current.typography.title2)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text("Ten kod QR nie zawiera danych kontaktu AirLink")
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
        case .contactExists:
            VStack(spacing: AppTheme.current.spacing.sm) {
                Text("Kontakt już istnieje")
                    .font(AppTheme.current.typography.title2)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text("Ten kontakt jest już zapisany w Twojej liście")
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
        case .error(let error):
            VStack(spacing: AppTheme.current.spacing.sm) {
                Text("Błąd skanowania")
                    .font(AppTheme.current.typography.title2)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text(error.localizedDescription)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    private var resultActions: some View {
        switch result {
        case .success:
            VStack(spacing: AppTheme.current.spacing.md) {
                Button("Dodaj kontakt") {
                    onAddContact()
                }
                .buttonStyle(.borderedProminent)
                .tint(AirLinkColors.primary)
                
                Button("Skanuj ponownie") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .tint(AirLinkColors.textSecondary)
            }
            
        default:
            Button("Skanuj ponownie") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(AirLinkColors.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    QRScannerView()
        .withAppTheme()
        .environment(QRService.createMockService())
        .environment(ContactService.createMockService())
        .environment(NavigationCoordinator.createMockCoordinator())
}
