//
//  MediaService.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import UIKit
import Photos
import Combine
import AVFoundation

// MARK: - MediaService

/// Serwis odpowiedzialny za zarządzanie mediami w AirLink
/// Obsługuje kompresję zdjęć, zarządzanie galerią i optymalizację transferu
@Observable
final class MediaService {
    
    // MARK: - Properties
    
    /// Status uprawnień do galerii zdjęć
    private(set) var photoLibraryPermissionStatus: PHAuthorizationStatus = .notDetermined
    
    /// Czy kompresja jest w toku
    private(set) var isCompressing = false
    
    /// Progress obecnej kompresji (0.0 - 1.0)
    private(set) var compressionProgress: Double = 0.0
    
    /// Cache skompresowanych obrazów
    private var compressionCache: [String: CachedImage] = [:]
    
    /// Queue do operacji kompresji
    private let compressionQueue = DispatchQueue(label: "com.airlink.compression", qos: .userInitiated)
    
    /// Manager do zarządzania cache
    private let cacheManager = ImageCacheManager()
    
    /// Maksymalny rozmiar cache (w MB)
    private let maxCacheSize: Int = 100
    
    // MARK: - Publishers
    
    private let compressionProgressSubject = PassthroughSubject<Double, Never>()
    var compressionProgressPublisher: AnyPublisher<Double, Never> {
        compressionProgressSubject.eraseToAnyPublisher()
    }
    
    private let photoLibraryPermissionSubject = PassthroughSubject<PHAuthorizationStatus, Never>()
    var photoLibraryPermissionPublisher: AnyPublisher<PHAuthorizationStatus, Never> {
        photoLibraryPermissionSubject.eraseToAnyPublisher()
    }
    
    private let compressionCompletedSubject = PassthroughSubject<CompressionResult, Never>()
    var compressionCompletedPublisher: AnyPublisher<CompressionResult, Never> {
        compressionCompletedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    init() {
        checkPhotoLibraryPermission()
        setupCacheCleanup()
    }
    
    // MARK: - Photo Library Access
    
    /// Sprawdza uprawnienia do galerii zdjęć
    func checkPhotoLibraryPermission() {
        photoLibraryPermissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    /// Żąda uprawnień do galerii zdjęć
    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        
        DispatchQueue.main.async { [weak self] in
            self?.photoLibraryPermissionStatus = status
            self?.photoLibraryPermissionSubject.send(status)
        }
        
        return status
    }
    
    /// Sprawdza czy można uzyskać dostęp do galerii
    func canAccessPhotoLibrary() -> Bool {
        return photoLibraryPermissionStatus == .authorized || photoLibraryPermissionStatus == .limited
    }
    
    // MARK: - Image Compression
    
    /// Kompresuje obraz do wysłania przez sieć
    func compressImageForTransfer(
        _ image: UIImage,
        quality: CompressionQuality = .balanced
    ) async throws -> MediaAttachment {
        
        guard !isCompressing else {
            throw MediaServiceError.compressionInProgress
        }
        
        isCompressing = true
        compressionProgress = 0.0
        
        defer {
            isCompressing = false
            compressionProgress = 0.0
        }
        
        do {
            let result = try await performImageCompression(image, quality: quality)
            
            DispatchQueue.main.async { [weak self] in
                self?.compressionCompletedSubject.send(.success(result))
            }
            
            return result
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.compressionCompletedSubject.send(.failure(error))
            }
            throw error
        }
    }
    
    /// Wykonuje kompresję obrazu
    private func performImageCompression(
        _ image: UIImage,
        quality: CompressionQuality
    ) async throws -> MediaAttachment {
        
        return try await withCheckedThrowingContinuation { continuation in
            compressionQueue.async { [weak self] in
                do {
                    guard let self = self else {
                        continuation.resume(throwing: MediaServiceError.operationCancelled)
                        return
                    }
                    
                    // Krok 1: Resize obrazu (20% progress)
                    self.updateProgress(0.2)
                    let resizedImage = self.resizeImage(image, for: quality)
                    
                    // Krok 2: Kompresja JPEG (60% progress)
                    self.updateProgress(0.6)
                    guard let compressedData = resizedImage.jpegData(compressionQuality: quality.jpegQuality) else {
                        continuation.resume(throwing: MediaServiceError.compressionFailed)
                        return
                    }
                    
                    // Krok 3: Generowanie thumbnail (80% progress)
                    self.updateProgress(0.8)
                    let thumbnail = self.generateThumbnail(from: resizedImage)
                    let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
                    
                    // Krok 4: Tworzenie MediaAttachment (100% progress)
                    self.updateProgress(1.0)
                    
                    let attachment = MediaAttachment(
                        type: .image,
                        compressedData: compressedData,
                        thumbnailData: thumbnailData,
                        compressionLevel: Double(quality.jpegQuality)
                    )
                    
                    // Ustawienie wymiarów
                    attachment.setDimensions(
                        width: Int(resizedImage.size.width),
                        height: Int(resizedImage.size.height)
                    )
                    
                    // Informacje o kompresji
                    if let originalData = image.jpegData(compressionQuality: 1.0) {
                        attachment.setCompressionInfo(
                            originalSize: originalData.count,
                            compressedSize: compressedData.count,
                            level: Double(quality.jpegQuality)
                        )
                    }
                    
                    continuation.resume(returning: attachment)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Zmienia rozmiar obrazu zgodnie z jakością
    private func resizeImage(_ image: UIImage, for quality: CompressionQuality) -> UIImage {
        let targetSize = quality.maxSize
        let originalSize = image.size
        
        // Sprawdź czy resize jest potrzebny
        if originalSize.width <= targetSize.width && originalSize.height <= targetSize.height {
            return image
        }
        
        // Oblicz nowy rozmiar zachowując proporcje
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
        
        // Renderuj nowy obraz
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Generuje thumbnail z obrazu
    private func generateThumbnail(from image: UIImage) -> UIImage {
        let thumbnailSize = AppConstants.Connectivity.thumbnailSize
        
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
    }
    
    /// Aktualizuje progress kompresji
    private func updateProgress(_ progress: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.compressionProgress = progress
            self?.compressionProgressSubject.send(progress)
        }
    }
    
    // MARK: - Image Processing
    
    /// Przygotowuje obraz do wyświetlenia (decode, cache)
    func prepareImageForDisplay(_ attachment: MediaAttachment) async -> UIImage? {
        // Sprawdź cache
        if let cachedImage = getCachedImage(for: attachment.id) {
            return cachedImage.image
        }
        
        // Dekoduj obraz
        guard let image = UIImage(data: attachment.compressedData) else {
            return nil
        }
        
        // Dodaj do cache
        cacheImage(image, for: attachment.id, size: attachment.compressedFileSize)
        
        return image
    }
    
    /// Przygotowuje thumbnail do wyświetlenia
    func prepareThumbnailForDisplay(_ attachment: MediaAttachment) -> UIImage? {
        guard let thumbnailData = attachment.thumbnailData else {
            return generateThumbnailFromAttachment(attachment)
        }
        
        return UIImage(data: thumbnailData)
    }
    
    /// Generuje thumbnail z załącznika jeśli nie ma
    private func generateThumbnailFromAttachment(_ attachment: MediaAttachment) -> UIImage? {
        guard let image = UIImage(data: attachment.compressedData) else {
            return nil
        }
        
        return generateThumbnail(from: image)
    }
    
    // MARK: - Photo Library Integration
    
    /// Pobiera ostatnie zdjęcia z galerii
    func fetchRecentPhotos(limit: Int = 20) async throws -> [PHAsset] {
        guard canAccessPhotoLibrary() else {
            throw MediaServiceError.photoLibraryAccessDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = limit
            
            let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            var assets: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
            continuation.resume(returning: assets)
        }
    }
    
    /// Ładuje obraz z PHAsset
    func loadImage(from asset: PHAsset, targetSize: CGSize = CGSize(width: 300, height: 300)) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: MediaServiceError.imageLoadFailed)
                }
            }
        }
    }
    
    /// Ładuje pełny rozmiar obrazu z PHAsset
    func loadFullSizeImage(from asset: PHAsset) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                guard let data = data, let image = UIImage(data: data) else {
                    continuation.resume(throwing: MediaServiceError.imageLoadFailed)
                    return
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    
    // MARK: - Cache Management
    
    /// Pobiera obraz z cache
    private func getCachedImage(for id: String) -> CachedImage? {
        return compressionCache[id]
    }
    
    /// Dodaje obraz do cache
    private func cacheImage(_ image: UIImage, for id: String, size: Int) {
        let cachedImage = CachedImage(
            image: image,
            size: size,
            timestamp: Date()
        )
        
        compressionCache[id] = cachedImage
        
        // Sprawdź czy trzeba wyczyścić cache
        cleanupCacheIfNeeded()
    }
    
    /// Czyści cache jeśli potrzeba
    private func cleanupCacheIfNeeded() {
        let totalSize = compressionCache.values.reduce(0) { $0 + $1.size }
        let maxSizeBytes = maxCacheSize * 1024 * 1024 // MB -> bytes
        
        if totalSize > maxSizeBytes {
            // Usuń najstarsze obrazy
            let sortedItems = compressionCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let itemsToRemove = sortedItems.prefix(sortedItems.count / 2) // Usuń połowę
            
            for (key, _) in itemsToRemove {
                compressionCache.removeValue(forKey: key)
            }
            
            print("🗑️ Cleaned up image cache")
        }
    }
    
    /// Czyści cały cache
    func clearCache() {
        compressionCache.removeAll()
        print("🗑️ Cleared image cache")
    }
    
    /// Konfiguruje automatyczne czyszczenie cache
    private func setupCacheCleanup() {
        // Czyszczenie co 30 minut
        Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            self?.cleanupCacheIfNeeded()
        }
    }
    
    // MARK: - Utility Methods
    
    /// Sprawdza czy obraz wymaga kompresji
    func imageNeedsCompression(_ image: UIImage, maxSize: Int = AppConstants.Connectivity.maxImageSize) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return false }
        return data.count > maxSize
    }
    
    /// Szacuje rozmiar po kompresji
    func estimateCompressedSize(_ image: UIImage, quality: CompressionQuality) -> Int {
        let resizedImage = resizeImage(image, for: quality)
        guard let data = resizedImage.jpegData(compressionQuality: quality.jpegQuality) else {
            return 0
        }
        return data.count
    }
    
    /// Sprawdza czy format pliku jest obsługiwany
    func isSupportedImageFormat(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        
        let type = CGImageSourceGetType(source)
        let supportedTypes: [CFString] = [kUTTypeJPEG, kUTTypePNG, kUTTypeHEIF, kUTTypeHEIC]
        
        return supportedTypes.contains { CFStringCompare(type, $0, .compareCaseInsensitive) == .compareEqualTo }
    }
    
    /// Otwiera ustawienia aplikacji dla uprawnień galerii
    func openPhotoLibrarySettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Data Models

/// Jakość kompresji obrazu
enum CompressionQuality {
    case high       // Wysoka jakość, mniejsza kompresja
    case balanced   // Zbalansowana jakość i rozmiar
    case low        // Niska jakość, maksymalna kompresja
    
    var jpegQuality: CGFloat {
        switch self {
        case .high: return 0.8
        case .balanced: return AppConstants.Connectivity.defaultImageCompressionQuality // 0.7
        case .low: return 0.5
        }
    }
    
    var maxSize: CGSize {
        switch self {
        case .high: return CGSize(width: 1536, height: 1536)  // iPad resolution
        case .balanced: return AppConstants.Connectivity.maxCompressedImageSize // 1024x1024
        case .low: return CGSize(width: 512, height: 512)     // Bardzo mały
        }
    }
    
    var displayName: String {
        switch self {
        case .high: return "Wysoka jakość"
        case .balanced: return "Zbalansowana"
        case .low: return "Niska jakość"
        }
    }
}

/// Wynik kompresji
enum CompressionResult {
    case success(MediaAttachment)
    case failure(Error)
}

/// Obraz w cache
struct CachedImage {
    let image: UIImage
    let size: Int
    let timestamp: Date
}

/// Manager cache'u obrazów
class ImageCacheManager {
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        cache.countLimit = 50 // Maksymalnie 50 obrazów
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: imageCost(image))
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    private func imageCost(_ image: UIImage) -> Int {
        return Int(image.size.width * image.size.height * 4) // 4 bytes per pixel (RGBA)
    }
}

// MARK: - Media Service Errors

enum MediaServiceError: LocalizedError {
    case photoLibraryAccessDenied
    case imageLoadFailed
    case compressionFailed
    case compressionInProgress
    case operationCancelled
    case unsupportedFormat
    case fileTooLarge
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Brak dostępu do galerii zdjęć"
        case .imageLoadFailed:
            return "Nie udało się załadować obrazu"
        case .compressionFailed:
            return "Nie udało się skompresować obrazu"
        case .compressionInProgress:
            return "Kompresja jest już w toku"
        case .operationCancelled:
            return "Operacja została anulowana"
        case .unsupportedFormat:
            return "Nieobsługiwany format pliku"
        case .fileTooLarge:
            return "Plik jest zbyt duży"
        case .cacheError:
            return "Błąd cache'u obrazów"
        }
    }
}

// MARK: - Extensions

extension MediaService {
    
    /// Sprawdza czy może rozpocząć kompresję
    func canStartCompression() -> Bool {
        return !isCompressing
    }
    
    /// Zwraca status uprawnień do galerii jako tekst
    func getPhotoLibraryPermissionStatusText() -> String {
        switch photoLibraryPermissionStatus {
        case .notDetermined:
            return "Nie określono"
        case .restricted:
            return "Ograniczone"
        case .denied:
            return "Odmówiono"
        case .authorized:
            return "Udzielono"
        case .limited:
            return "Ograniczone"
        @unknown default:
            return "Nieznany"
        }
    }
    
    /// Zwraca informacje o cache
    func getCacheInfo() -> (count: Int, sizeBytes: Int) {
        let count = compressionCache.count
        let size = compressionCache.values.reduce(0) { $0 + $1.size }
        return (count, size)
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension MediaService {
    
    /// Tworzy mock service dla preview i testów
    static func createMockService() -> MediaService {
        return MediaService()
    }
    
    /// Generuje przykładowy MediaAttachment
    func createSampleAttachment() -> MediaAttachment? {
        // Utwórz przykładowy obraz
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        return MediaAttachment.createImageAttachment(from: image)
    }
    
    /// Symuluje kompresję z progress
    func simulateCompression(duration: TimeInterval = 2.0) {
        isCompressing = true
        
        let steps = 10
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                let progress = Double(i) / Double(steps)
                self?.compressionProgress = progress
                self?.compressionProgressSubject.send(progress)
                
                if i == steps {
                    self?.isCompressing = false
                }
            }
        }
    }
}
#endif
