//
//  Constants.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI
import Foundation

// MARK: - App Constants

struct AppConstants {
    
    // MARK: - App Info
    
    static let appName = "AirLink"
    static let appVersion = "1.0.0"
    static let minimumIOSVersion = "17.0"
    
    // MARK: - Colors
    
    struct Colors {
        /// Główny kolor akcentu aplikacji - #0263FF (niebieski)
        static let accent = Color(hex: "#0263FF")
        
        /// Wersje koloru akcentu
        static let accentLight = Color(hex: "#4D8BFF")
        static let accentDark = Color(hex: "#0052D1")
        
        /// Kolory systemowe
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        /// Kolory tekstu
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        
        /// Kolory wiadomości
        static let myMessageBackground = accent
        static let otherMessageBackground = Color(.systemGray5)
        static let myMessageText = Color.white
        static let otherMessageText = primaryText
        
        /// Kolory statusów
        static let onlineGreen = Color.green
        static let offlineGray = Color(.systemGray3)
        static let meshBlue = Color.blue
        static let errorRed = Color.red
        static let warningOrange = Color.orange
        
        /// Kolory sygnału (0-5 kresek)
        static let signalWeak = Color.red        // 1-2 kreski
        static let signalMedium = Color.orange   // 3 kreski
        static let signalStrong = Color.green    // 4-5 kresek
        static let signalNone = Color(.systemGray4) // 0 kresek
    }
    
    // MARK: - Spacing & Sizing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        
        /// Dla message bubbles
        static let messageBubble: CGFloat = 18
        
        /// Dla avatarów
        static let avatar: CGFloat = 20
    }
    
    struct Sizes {
        /// Rozmiary avatarów
        static let avatarSmall: CGFloat = 32
        static let avatarMedium: CGFloat = 40
        static let avatarLarge: CGFloat = 60
        static let avatarExtraLarge: CGFloat = 80
        
        /// Rozmiary ikon
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        
        /// Wysokości elementów UI
        static let tabBarHeight: CGFloat = 83
        static let navigationBarHeight: CGFloat = 44
        static let messageInputHeight: CGFloat = 44
        static let fabSize: CGFloat = 56
        
        /// Rozmiary signal indicator
        static let signalBarWidth: CGFloat = 3
        static let signalBarMaxHeight: CGFloat = 12
        static let signalBarSpacing: CGFloat = 2
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        /// Dla message bubbles
        static let messageBubble = SwiftUI.Animation.spring(
            response: 0.6,
            dampingFraction: 0.8
        )
        
        /// Dla FAB
        static let fab = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.7
        )
        
        /// Dla signal strength
        static let signalUpdate = SwiftUI.Animation.easeInOut(duration: 0.4)
    }
    
    // MARK: - Typography
    
    struct Fonts {
        /// SF Pro - domyślna czcionka systemowa iOS
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        /// Custom dla message bubbles
        static let messageText = Font.body
        static let messageTime = Font.caption2.weight(.medium)
        
        /// Custom dla UI
        static let tabBarTitle = Font.caption.weight(.medium)
        static let buttonText = Font.body.weight(.semibold)
        static let navigationTitle = Font.title3.weight(.semibold)
    }
    
    // MARK: - Connectivity
    
    struct Connectivity {
        /// MultipeerConnectivity service type (max 15 znaków)
        static let serviceType = "airlink-chat"
        
        /// Maksymalny czas oczekiwania na połączenie
        static let connectionTimeout: TimeInterval = 30
        
        /// Interwał aktualizacji signal strength
        static let signalUpdateInterval: TimeInterval = 2
        
        /// Maksymalny rozmiar wiadomości (w bajtach)
        static let maxMessageSize = 64 * 1024 // 64KB
        
        /// Maksymalny rozmiar zdjęcia przed kompresją (w bajtach)
        static let maxImageSize = 10 * 1024 * 1024 // 10MB
        
        /// Domyślna jakość kompresji zdjęć
        static let defaultImageCompressionQuality: CGFloat = 0.7
        
        /// Maksymalne wymiary zdjęcia po kompresji
        static let maxCompressedImageSize = CGSize(width: 1024, height: 1024)
        
        /// Rozmiar thumbnail
        static let thumbnailSize = CGSize(width: 150, height: 150)
    }
    
    // MARK: - Limits
    
    struct Limits {
        /// Maksymalna długość pseudonimu
        static let maxNicknameLength = 30
        
        /// Maksymalna długość nazwy grupy
        static let maxGroupNameLength = 50
        
        /// Maksymalna długość wiadomości tekstowej
        static let maxMessageLength = 1000
        
        /// Maksymalna liczba uczestników w grupie
        static let maxGroupParticipants = 20
        
        /// Maksymalna liczba załączników na wiadomość
        static let maxAttachmentsPerMessage = 5
        
        /// Liczba dni po których stare wiadomości są archiwizowane
        static let messageArchiveDays = 30
    }
    
    // MARK: - UI Text
    
    struct UIText {
        // Empty states
        static let noChatsTitle = "Brak rozmów"
        static let noChatsSubtitle = "Naciśnij + żeby rozpocząć czat"
        static let noContactsTitle = "Brak kontaktów"
        static let noContactsSubtitle = "Zeskanuj kod QR aby dodać pierwszą osobę"
        
        // Connectivity messages
        static let bluetoothOffTitle = "Bluetooth wyłączony"
        static let bluetoothOffMessage = "Włącz Bluetooth żeby łączyć się z innymi"
        static let searchingTitle = "Szukam urządzeń..."
        static let searchingMessage = "Upewnij się, że inne osoby mają włączoną aplikację"
        
        // Permissions
        static let cameraPermissionTitle = "Potrzebny dostęp do kamery"
        static let cameraPermissionMessage = "Aby skanować kody QR, włącz dostęp do kamery w Ustawieniach"
        static let photosPermissionTitle = "Potrzebny dostęp do zdjęć"
        static let photosPermissionMessage = "Aby wysyłać zdjęcia, włącz dostęp do galerii w Ustawieniach"
    }
    
    // MARK: - Haptics
    
    struct Haptics {
        static let light = UIImpactFeedbackGenerator.FeedbackStyle.light
        static let medium = UIImpactFeedbackGenerator.FeedbackStyle.medium
        static let heavy = UIImpactFeedbackGenerator.FeedbackStyle.heavy
        
        static let success = UINotificationFeedbackGenerator.FeedbackType.success
        static let warning = UINotificationFeedbackGenerator.FeedbackType.warning
        static let error = UINotificationFeedbackGenerator.FeedbackType.error
    }
    
    // MARK: - SF Symbols
    
    struct Icons {
        // Tab bar
        static let homeTab = "message"
        static let contactsTab = "person.2"
        static let settingsTab = "gearshape"
        
        // Navigation
        static let back = "chevron.left"
        static let close = "xmark"
        static let add = "plus"
        static let search = "magnifyingglass"
        static let more = "ellipsis"
        
        // Chat
        static let send = "arrow.up.circle.fill"
        static let camera = "camera"
        static let photo = "photo"
        static let attach = "paperclip"
        
        // Status indicators
        static let online = "circle.fill"
        static let offline = "circle"
        static let mesh = "network"
        static let signal0 = "antenna.radiowaves.left.and.right.slash"
        static let signal1 = "antenna.radiowaves.left.and.right"
        
        // QR
        static let qrCode = "qrcode"
        static let qrScanner = "qrcode.viewfinder"
        
        // Settings
        static let profile = "person.circle"
        static let privacy = "lock.shield"
        static let storage = "internaldrive"
        static let haptics = "iphone.radiowaves.left.and.right"
        
        // Message status
        static let sending = "clock"
        static let delivered = "checkmark"
        static let failed = "exclamationmark.triangle"
        static let read = "checkmark.circle"
    }
}

// MARK: - Color Extension for Hex

extension Color {
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
