//
//  Contact.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftData

@Model
final class Contact {
    
    // MARK: - Properties
    
    /// Unikalny identyfikator kontaktu (z MultipeerConnectivity)
    @Attribute(.unique) var id: String
    
    /// Pseudonim wyświetlany w aplikacji
    var nickname: String
    
    /// Data dodania kontaktu
    var dateAdded: Date
    
    /// Data ostatniej aktywności (ostatnie połączenie)
    var lastSeen: Date?
    
    /// Avatar kontaktu - dane zdjęcia lub nil (wtedy generujemy literę)
    @Attribute(.externalStorage) var avatarData: Data?
    
    /// Czy kontakt jest obecnie online (w zasięgu)
    @Attribute(.transient) var isOnline: Bool = false
    
    /// Siła sygnału 0-5 kresek (transient - nie zapisujemy)
    @Attribute(.transient) var signalStrength: Int = 0
    
    /// Czy kontakt jest połączony przez mesh network
    @Attribute(.transient) var isConnectedViaMesh: Bool = false
    
    /// Relacja do czatów z tym kontaktem
    @Relationship(deleteRule: .nullify, inverse: \Chat.participants)
    var chats: [Chat] = []
    
    // MARK: - Initializer
    
    init(
        id: String,
        nickname: String,
        avatarData: Data? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.avatarData = avatarData
        self.dateAdded = Date()
        self.lastSeen = nil
        self.isOnline = false
        self.signalStrength = 0
        self.isConnectedViaMesh = false
    }
    
    // MARK: - Computed Properties
    
    /// Pierwsza litera pseudonimu do generowania avatara
    var firstLetter: String {
        String(nickname.prefix(1).uppercased())
    }
    
    /// Czy kontakt ma własny avatar (zdjęcie)
    var hasCustomAvatar: Bool {
        avatarData != nil
    }
    
    /// Status połączenia jako tekst
    var connectionStatus: String {
        if isOnline {
            return isConnectedViaMesh ? "Połączony przez mesh" : "Online"
        } else {
            return "Offline"
        }
    }
    
    /// Ostatnia aktywność jako sformatowany tekst
    var lastSeenText: String {
        guard let lastSeen = lastSeen else {
            return "Nigdy nie widziany"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        return "Ostatnio: \(formatter.localizedString(for: lastSeen, relativeTo: Date()))"
    }
}

// MARK: - Extensions

extension Contact: Identifiable {
    // ID już jest zdefiniowane jako String
}

extension Contact: Hashable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Contact {
    
    /// Aktualizuje status online kontaktu
    func updateOnlineStatus(isOnline: Bool, signalStrength: Int = 0, viaMesh: Bool = false) {
        self.isOnline = isOnline
        self.signalStrength = signalStrength
        self.isConnectedViaMesh = viaMesh
        
        if isOnline {
            self.lastSeen = Date()
        }
    }
    
    /// Aktualizuje avatar kontaktu
    func updateAvatar(_ imageData: Data?) {
        self.avatarData = imageData
    }
    
    /// Aktualizuje pseudonim kontaktu
    func updateNickname(_ newNickname: String) {
        self.nickname = newNickname
    }
}

// MARK: - Sample Data (dla testów i preview)

extension Contact {
    
    /// Przykładowy kontakt do testów
    static let sampleContact = Contact(
        id: "sample-contact-123",
        nickname: "Ania"
    )
    
    /// Przykładowy kontakt online
    static let sampleOnlineContact: Contact = {
        let contact = Contact(
            id: "online-contact-456",
            nickname: "Marek"
        )
        contact.updateOnlineStatus(isOnline: true, signalStrength: 4)
        return contact
    }()
    
    /// Przykładowy kontakt przez mesh
    static let sampleMeshContact: Contact = {
        let contact = Contact(
            id: "mesh-contact-789",
            nickname: "Kasia"
        )
        contact.updateOnlineStatus(isOnline: true, signalStrength: 2, viaMesh: true)
        return contact
    }()
}
