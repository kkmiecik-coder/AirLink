//
//  Message.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftData

@Model
final class Message {
    
    // MARK: - Properties
    
    /// Unikalny identyfikator wiadomości
    @Attribute(.unique) var id: String
    
    /// Treść wiadomości
    var content: String
    
    /// ID nadawcy wiadomości
    var senderID: String
    
    /// Data i czas wysłania wiadomości
    var timestamp: Date
    
    /// Typ wiadomości
    var type: MessageType
    
    /// Status dostarczenia wiadomości
    var deliveryStatus: DeliveryStatus
    
    /// Czy wiadomość została przeczytana przez aktualnego użytkownika
    var isRead: Bool = false
    
    /// Czy wiadomość została wysłana przez mesh network
    var sentViaMesh: Bool = false
    
    /// Liczba "skoków" przez mesh network (0 = bezpośrednio)
    var meshHops: Int = 0
    
    /// Relacja do czatu, do którego należy wiadomość
    @Relationship var chat: Chat?
    
    /// Załączniki medialne do wiadomości
    @Relationship(deleteRule: .cascade, inverse: \MediaAttachment.message)
    var attachments: [MediaAttachment] = []
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        content: String,
        senderID: String,
        type: MessageType = .text,
        chat: Chat? = nil
    ) {
        self.id = id
        self.content = content
        self.senderID = senderID
        self.timestamp = Date()
        self.type = type
        self.deliveryStatus = .sending
        self.chat = chat
        self.sentViaMesh = false
        self.meshHops = 0
    }
    
    // MARK: - Computed Properties
    
    /// Czy wiadomość ma załączniki
    var hasAttachments: Bool {
        !attachments.isEmpty
    }
    
    /// Czy to wiadomość z obrazem
    var hasImages: Bool {
        attachments.contains { $0.type == .image }
    }
    
    /// Czy wiadomość została dostarczona
    var isDelivered: Bool {
        deliveryStatus == .delivered
    }
    
    /// Czy wiadomość nie została dostarczona
    var isFailed: Bool {
        deliveryStatus == .failed
    }
    
    /// Czy wiadomość jest w trakcie wysyłania
    var isSending: Bool {
        deliveryStatus == .sending
    }
    
    /// Sformatowany czas wiadomości
    var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pl_PL")
        return formatter.string(from: timestamp)
    }
    
    /// Sformatowana data wiadomości
    var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pl_PL")
        return formatter.string(from: timestamp)
    }
    
    /// Czy wiadomość jest z dzisiaj
    var isToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }
    
    /// Czy wiadomość jest z wczoraj
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(timestamp)
    }
    
    /// Tekst do wyświetlenia w preview (z załącznikami)
    var previewText: String {
        if type == .text && !content.isEmpty {
            return content
        }
        
        if hasImages {
            let imageCount = attachments.filter { $0.type == .image }.count
            if imageCount == 1 {
                return "📷 Zdjęcie"
            } else {
                return "📷 \(imageCount) zdjęć"
            }
        }
        
        return "Wiadomość"
    }
    
    /// Status mesh jako tekst
    var meshStatusText: String {
        if !sentViaMesh {
            return "Bezpośrednio"
        }
        
        if meshHops == 0 {
            return "Mesh"
        } else {
            return "Mesh (\(meshHops) skoków)"
        }
    }
    
    /// Ikona statusu dostarczenia
    var deliveryStatusIcon: String {
        switch deliveryStatus {
        case .sending:
            return "clock"
        case .delivered:
            return "checkmark"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Message Type

enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case system = "system" // Wiadomości systemowe (dołączył do grupy, etc.)
    
    var displayName: String {
        switch self {
        case .text:
            return "Tekst"
        case .image:
            return "Zdjęcie"
        case .system:
            return "System"
        }
    }
}

// MARK: - Delivery Status

enum DeliveryStatus: String, Codable, CaseIterable {
    case sending = "sending"
    case delivered = "delivered"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .sending:
            return "Wysyłanie"
        case .delivered:
            return "Dostarczone"
        case .failed:
            return "Błąd"
        }
    }
}

// MARK: - Extensions

extension Message: Identifiable {
    // ID już jest zdefiniowane jako String
}

extension Message: Hashable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Message {
    
    /// Oznacza wiadomość jako przeczytaną
    func markAsRead() {
        isRead = true
    }
    
    /// Aktualizuje status dostarczenia
    func updateDeliveryStatus(_ status: DeliveryStatus) {
        deliveryStatus = status
    }
    
    /// Ustawia informacje o mesh networking
    func setMeshInfo(sentViaMesh: Bool, hops: Int = 0) {
        self.sentViaMesh = sentViaMesh
        self.meshHops = hops
    }
    
    /// Dodaje załącznik do wiadomości
    func addAttachment(_ attachment: MediaAttachment) {
        attachments.append(attachment)
        
        // Aktualizuj typ wiadomości jeśli to pierwsze zdjęcie
        if attachment.type == .image && type == .text {
            type = .image
        }
    }
    
    /// Usuwa załącznik z wiadomości
    func removeAttachment(_ attachment: MediaAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        
        // Sprawdź czy zmienić typ wiadomości
        if !hasImages && type == .image {
            type = .text
        }
    }
}

// MARK: - Sample Data

extension Message {
    
    /// Przykładowa wiadomość tekstowa
    static let sampleTextMessage = Message(
        content: "Cześć! Jak leci podróż?",
        senderID: "user-123"
    )
    
    /// Przykładowa wiadomość dostarczona
    static let sampleDeliveredMessage: Message = {
        let message = Message(
            content: "Już prawie lądujemy! 🛬",
            senderID: "user-456"
        )
        message.updateDeliveryStatus(.delivered)
        message.markAsRead()
        return message
    }()
    
    /// Przykładowa wiadomość przez mesh
    static let sampleMeshMessage: Message = {
        let message = Message(
            content: "Widać góry przez okno!",
            senderID: "user-789"
        )
        message.setMeshInfo(sentViaMesh: true, hops: 2)
        message.updateDeliveryStatus(.delivered)
        return message
    }()
    
    /// Przykładowa wiadomość z błędem
    static let sampleFailedMessage: Message = {
        let message = Message(
            content: "Ta wiadomość się nie wysłała...",
            senderID: "user-123"
        )
        message.updateDeliveryStatus(.failed)
        return message
    }()
    
    /// Przykładowa wiadomość systemowa
    static let sampleSystemMessage: Message = {
        let message = Message(
            content: "Ania dołączyła do grupy",
            senderID: "system",
            type: .system
        )
        message.updateDeliveryStatus(.delivered)
        return message
    }()
    
    /// Przykładowa wiadomość ze zdjęciem
    static let sampleImageMessage: Message = {
        let message = Message(
            content: "Sprawdźcie ten widok!",
            senderID: "user-456",
            type: .image
        )
        message.updateDeliveryStatus(.delivered)
        return message
    }()
}
