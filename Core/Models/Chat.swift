//
//  Chat.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftData

@Model
final class Chat {
    
    // MARK: - Properties
    
    /// Unikalny identyfikator czatu
    @Attribute(.unique) var id: String
    
    /// Nazwa czatu (dla grup) lub nil (dla DM - generujemy z uczestników)
    var name: String?
    
    /// Typ czatu
    var type: ChatType
    
    /// Data utworzenia czatu
    var dateCreated: Date
    
    /// Data ostatniej wiadomości
    var lastMessageDate: Date?
    
    /// Treść ostatniej wiadomości (do wyświetlenia na liście)
    var lastMessagePreview: String?
    
    /// ID autora ostatniej wiadomości
    var lastMessageAuthorID: String?
    
    /// Liczba nieprzeczytanych wiadomości
    var unreadCount: Int = 0
    
    /// Czy czat jest wyciszony
    var isMuted: Bool = false
    
    /// Czy czat jest aktywny (uczestnicy online)
    @Attribute(.transient) var isActive: Bool = false
    
    /// Lista uczestników czatu
    @Relationship(deleteRule: .nullify)
    var participants: [Contact] = []
    
    /// Wiadomości w czacie
    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message] = []
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        name: String? = nil,
        type: ChatType,
        participants: [Contact] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.dateCreated = Date()
        self.participants = participants
        self.isActive = false
    }
    
    // MARK: - Computed Properties
    
    /// Wyświetlana nazwa czatu
    var displayName: String {
        if let name = name {
            return name
        }
        
        // Dla DM generujemy nazwę z uczestników
        if type == .directMessage {
            let names = participants.map { $0.nickname }
            return names.joined(separator: ", ")
        }
        
        // Dla grup bez nazwy
        return "Grupa \(participants.count) osób"
    }
    
    /// Czy to czat grupowy
    var isGroup: Bool {
        type == .group
    }
    
    /// Czy to czat prywatny (DM)
    var isDirectMessage: Bool {
        type == .directMessage
    }
    
    /// Liczba uczestników
    var participantCount: Int {
        participants.count
    }
    
    /// Czy wszyscy uczestnicy są online
    var allParticipantsOnline: Bool {
        !participants.isEmpty && participants.allSatisfy { $0.isOnline }
    }
    
    /// Liczba uczestników online
    var onlineParticipantsCount: Int {
        participants.filter { $0.isOnline }.count
    }
    
    /// Status czatu jako tekst
    var statusText: String {
        if participants.isEmpty {
            return "Brak uczestników"
        }
        
        let onlineCount = onlineParticipantsCount
        
        if onlineCount == 0 {
            return "Wszyscy offline"
        } else if onlineCount == participantCount {
            return type == .directMessage ? "Online" : "Wszyscy online"
        } else {
            return "\(onlineCount)/\(participantCount) online"
        }
    }
    
    /// Ostatnia wiadomość sformatowana do wyświetlenia
    var lastMessageDisplay: String {
        guard let preview = lastMessagePreview else {
            return "Brak wiadomości"
        }
        
        // Dla grup pokazujemy autora
        if isGroup, let authorID = lastMessageAuthorID {
            let author = participants.first { $0.id == authorID }?.nickname ?? "Nieznany"
            return "\(author): \(preview)"
        }
        
        return preview
    }
    
    /// Data ostatniej wiadomości sformatowana
    var lastMessageTimeText: String {
        guard let date = lastMessageDate else {
            return ""
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Chat Type

enum ChatType: String, Codable, CaseIterable {
    case directMessage = "dm"
    case group = "group"
    
    var displayName: String {
        switch self {
        case .directMessage:
            return "Czat prywatny"
        case .group:
            return "Grupa"
        }
    }
}

// MARK: - Extensions

extension Chat: Identifiable {
    // ID już jest zdefiniowane jako String
}

extension Chat: Hashable {
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Chat {
    
    /// Dodaje uczestnika do czatu
    func addParticipant(_ contact: Contact) {
        if !participants.contains(where: { $0.id == contact.id }) {
            participants.append(contact)
        }
    }
    
    /// Usuwa uczestnika z czatu
    func removeParticipant(_ contact: Contact) {
        participants.removeAll { $0.id == contact.id }
    }
    
    /// Aktualizuje ostatnią wiadomość
    func updateLastMessage(_ message: Message) {
        lastMessageDate = message.timestamp
        lastMessagePreview = message.content
        lastMessageAuthorID = message.senderID
    }
    
    /// Oznacza wszystkie wiadomości jako przeczytane
    func markAsRead() {
        unreadCount = 0
    }
    
    /// Zwiększa licznik nieprzeczytanych wiadomości
    func incrementUnreadCount() {
        unreadCount += 1
    }
    
    /// Aktualizuje status aktywności czatu
    func updateActiveStatus() {
        isActive = onlineParticipantsCount > 0
    }
    
    /// Aktualizuje nazwę grupy
    func updateGroupName(_ newName: String) {
        if type == .group {
            self.name = newName
        }
    }
    
    /// Przełącza wyciszenie czatu
    func toggleMute() {
        isMuted.toggle()
    }
}

// MARK: - Sample Data

extension Chat {
    
    /// Przykładowy czat DM
    static let sampleDirectMessage: Chat = {
        let contact = Contact.sampleContact
        let chat = Chat(
            name: nil,
            type: .directMessage,
            participants: [contact]
        )
        chat.lastMessagePreview = "Cześć! Jak leci podróż?"
        chat.lastMessageDate = Date().addingTimeInterval(-300) // 5 minut temu
        chat.lastMessageAuthorID = contact.id
        chat.unreadCount = 2
        return chat
    }()
    
    /// Przykładowy czat grupowy
    static let sampleGroupChat: Chat = {
        let contacts = [
            Contact.sampleContact,
            Contact.sampleOnlineContact,
            Contact.sampleMeshContact
        ]
        
        let chat = Chat(
            name: "Lot do Warszawy",
            type: .group,
            participants: contacts
        )
        chat.lastMessagePreview = "Czy widzicie te chmury?"
        chat.lastMessageDate = Date().addingTimeInterval(-120) // 2 minuty temu
        chat.lastMessageAuthorID = contacts[1].id
        chat.unreadCount = 0
        return chat
    }()
    
    /// Przykładowy pusty czat
    static let sampleEmptyChat = Chat(
        name: "Nowa grupa",
        type: .group
    )
}
