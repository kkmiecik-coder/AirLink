//
//  MediaAttachment.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftData
import UIKit

@Model
final class MediaAttachment {
    
    // MARK: - Properties
    
    /// Unikalny identyfikator załącznika
    @Attribute(.unique) var id: String
    
    /// Typ załącznika
    var type: MediaType
    
    /// Oryginalna nazwa pliku
    var originalFileName: String?
    
    /// Rozmiar oryginalnego pliku w bajtach
    var originalFileSize: Int
    
    /// Data utworzenia załącznika
    var dateCreated: Date
    
    /// Skompresowane dane mediów do wysłania
    @Attribute(.externalStorage) var compressedData: Data
    
    /// Miniaturka do szybkiego wyświetlania
    @Attribute(.externalStorage) var thumbnailData: Data?
    
    /// Szerokość obrazu (jeśli to zdjęcie)
    var width: Int?
    
    /// Wysokość obrazu (jeśli to zdjęcie)
    var height: Int?
    
    /// Poziom kompresji zastosowany (0.0 - 1.0)
    var compressionLevel: Double
    
    /// Rozmiar skompresowanego pliku w bajtach
    var compressedFileSize: Int
    
    /// Czy załącznik został pomyślnie przesłany
    var isUploaded: Bool = false
    
    /// Czy załącznik został pobrany (dla przychodzących)
    var isDownloaded: Bool = true
    
    /// Progress pobierania/wysyłania (0.0 - 1.0)
    @Attribute(.transient) var transferProgress: Double = 0.0
    
    /// Relacja do wiadomości, do której należy załącznik
    @Relationship var message: Message?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        type: MediaType,
        compressedData: Data,
        thumbnailData: Data? = nil,
        originalFileName: String? = nil,
        compressionLevel: Double = 0.7
    ) {
        self.id = id
        self.type = type
        self.compressedData = compressedData
        self.thumbnailData = thumbnailData
        self.originalFileName = originalFileName
        self.compressionLevel = compressionLevel
        self.dateCreated = Date()
        self.originalFileSize = compressedData.count
        self.compressedFileSize = compressedData.count
        self.isDownloaded = true
        self.transferProgress = 1.0
    }
    
    // MARK: - Computed Properties
    
    /// Czy to załącznik obrazu
    var isImage: Bool {
        type == .image
    }
    
    /// Czy załącznik ma wymiary (jest obrazem)
    var hasDimensions: Bool {
        width != nil && height != nil
    }
    
    /// Aspect ratio obrazu
    var aspectRatio: Double? {
        guard let width = width, let height = height, height > 0 else {
            return nil
        }
        return Double(width) / Double(height)
    }
    
    /// Czy obraz jest panoramiczny (szeroki)
    var isPanorama: Bool {
        guard let ratio = aspectRatio else { return false }
        return ratio > 2.0
    }
    
    /// Czy obraz jest pionowy
    var isPortrait: Bool {
        guard let ratio = aspectRatio else { return false }
        return ratio < 1.0
    }
    
    /// Sformatowany rozmiar pliku
    var fileSizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(compressedFileSize), countStyle: .file)
    }
    
    /// Sformatowany rozmiar oryginalny
    var originalFileSizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(originalFileSize), countStyle: .file)
    }
    
    /// Procent kompresji
    var compressionPercentage: Double {
        guard originalFileSize > 0 else { return 0 }
        return Double(compressedFileSize) / Double(originalFileSize)
    }
    
    /// Tekst kompresji do wyświetlenia
    var compressionText: String {
        let percentage = Int((1.0 - compressionPercentage) * 100)
        return "Skompresowane o \(percentage)%"
    }
    
    /// Wymiary jako tekst
    var dimensionsText: String {
        guard let width = width, let height = height else {
            return "Nieznane wymiary"
        }
        return "\(width) × \(height)"
    }
    
    /// Status transferu jako tekst
    var transferStatusText: String {
        if !isDownloaded {
            return "Pobieranie... \(Int(transferProgress * 100))%"
        } else if !isUploaded {
            return "Wysyłanie... \(Int(transferProgress * 100))%"
        } else {
            return "Gotowe"
        }
    }
    
    /// Czy transfer jest w toku
    var isTransferring: Bool {
        (!isDownloaded || !isUploaded) && transferProgress < 1.0
    }
}

// MARK: - Media Type

enum MediaType: String, Codable, CaseIterable {
    case image = "image"
    // case video = "video" // Na przyszłość
    // case audio = "audio" // Na przyszłość
    
    var displayName: String {
        switch self {
        case .image:
            return "Zdjęcie"
        }
    }
    
    var icon: String {
        switch self {
        case .image:
            return "photo"
        }
    }
}

// MARK: - Extensions

extension MediaAttachment: Identifiable {
    // ID już jest zdefiniowane jako String
}

extension MediaAttachment: Hashable {
    static func == (lhs: MediaAttachment, rhs: MediaAttachment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension MediaAttachment {
    
    /// Aktualizuje progress transferu
    func updateTransferProgress(_ progress: Double) {
        transferProgress = max(0.0, min(1.0, progress))
    }
    
    /// Oznacza jako przesłane
    func markAsUploaded() {
        isUploaded = true
        transferProgress = 1.0
    }
    
    /// Oznacza jako pobrane
    func markAsDownloaded() {
        isDownloaded = true
        transferProgress = 1.0
    }
    
    /// Ustawia wymiary obrazu
    func setDimensions(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    /// Ustawia informacje o kompresji
    func setCompressionInfo(
        originalSize: Int,
        compressedSize: Int,
        level: Double
    ) {
        self.originalFileSize = originalSize
        self.compressedFileSize = compressedSize
        self.compressionLevel = level
    }
}

// MARK: - Helper Factory Methods

extension MediaAttachment {
    
    /// Tworzy załącznik obrazu z UIImage
    static func createImageAttachment(
        from image: UIImage,
        compressionQuality: CGFloat = 0.7,
        maxSize: CGSize = CGSize(width: 1024, height: 1024)
    ) -> MediaAttachment? {
        
        // Resize obrazu jeśli potrzeba
        let resizedImage = image.resized(to: maxSize)
        
        // Kompresja do JPEG
        guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        // Tworzenie miniaturki
        let thumbnailSize = CGSize(width: 150, height: 150)
        let thumbnail = resizedImage.resized(to: thumbnailSize)
        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
        
        // Tworzenie załącznika
        let attachment = MediaAttachment(
            type: .image,
            compressedData: compressedData,
            thumbnailData: thumbnailData,
            compressionLevel: Double(compressionQuality)
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
                level: Double(compressionQuality)
            )
        }
        
        return attachment
    }
    
    /// Konwertuje dane z powrotem na UIImage
    func toUIImage() -> UIImage? {
        return UIImage(data: compressedData)
    }
    
    /// Konwertuje thumbnail na UIImage
    func thumbnailUIImage() -> UIImage? {
        guard let thumbnailData = thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }
}

// MARK: - Sample Data

extension MediaAttachment {
    
    /// Przykładowy załącznik obrazu
    static let sampleImageAttachment: MediaAttachment = {
        // Dummy data dla przykładu
        let dummyImageData = Data(repeating: 0, count: 1024)
        let attachment = MediaAttachment(
            type: .image,
            compressedData: dummyImageData,
            originalFileName: "widok_z_samolotu.jpg",
            compressionLevel: 0.7
        )
        attachment.setDimensions(width: 1024, height: 768)
        attachment.setCompressionInfo(
            originalSize: 2048,
            compressedSize: 1024,
            level: 0.7
        )
        attachment.markAsUploaded()
        return attachment
    }()
    
    /// Przykładowy załącznik panoramiczny
    static let samplePanoramaAttachment: MediaAttachment = {
        let dummyData = Data(repeating: 0, count: 2048)
        let attachment = MediaAttachment(
            type: .image,
            compressedData: dummyData,
            originalFileName: "panorama_chmur.jpg",
            compressionLevel: 0.6
        )
        attachment.setDimensions(width: 2048, height: 512)
        attachment.markAsUploaded()
        return attachment
    }()
}

// MARK: - UIImage Extension for Resizing

private extension UIImage {
    
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
