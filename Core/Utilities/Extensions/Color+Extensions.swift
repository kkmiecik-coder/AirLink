//
//  Color+Extensions.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    
    // MARK: - Hex Initializer
    
    /// Tworzy kolor z hex stringa (np. "#FF0000" lub "FF0000")
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
    
    // MARK: - Hex String Representation
    
    /// Zwraca hex reprezentację koloru
    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
    
    // MARK: - Color Analysis
    
    /// Sprawdza czy kolor jest jasny
    var isLight: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Formuła luminancji
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.5
    }
    
    /// Sprawdza czy kolor jest ciemny
    var isDark: Bool {
        !isLight
    }
    
    // MARK: - Color Manipulation
    
    /// Zwraca jaśniejszą wersję koloru
    func lighter(by percentage: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        brightness = min(brightness + CGFloat(percentage), 1.0)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
    
    /// Zwraca ciemniejszą wersję koloru
    func darker(by percentage: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        brightness = max(brightness - CGFloat(percentage), 0.0)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
    
    /// Zwraca nasycenie koloru
    func saturated(by percentage: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        saturation = min(saturation + CGFloat(percentage), 1.0)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
    
    /// Zwraca odbarwioną wersję koloru
    func desaturated(by percentage: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        saturation = max(saturation - CGFloat(percentage), 0.0)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
}

// MARK: - AirLink Color Extensions

extension AirLinkColors {
    
    // MARK: - Avatar Gradients
    
    /// Generuje gradient avatara na podstawie tekstu
    static func avatarGradient(for text: String) -> LinearGradient {
        let hash = text.djb2hash
        let gradientIndex = abs(hash) % avatarGradients.count
        return avatarGradients[gradientIndex]
    }
    
    /// Predefiniowane gradienty avatarów
    private static let avatarGradients: [LinearGradient] = [
        // Niebieski gradient (główny)
        LinearGradient(
            colors: [Color(hex: "#0263FF"), Color(hex: "#4D8BFF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // Zielony gradient
        LinearGradient(
            colors: [Color(hex: "#10B981"), Color(hex: "#34D399")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // Fioletowy gradient
        LinearGradient(
            colors: [Color(hex: "#8B5CF6"), Color(hex: "#A78BFA")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // Różowy gradient
        LinearGradient(
            colors: [Color(hex: "#EC4899"), Color(hex: "#F472B6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // Pomarańczowy gradient
        LinearGradient(
            colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // Czerwony gradient
        LinearGradient(
            colors: [Color(hex: "#EF4444"), Color(hex: "#F87171")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // Indygo gradient
        LinearGradient(
            colors: [Color(hex: "#6366F1"), Color(hex: "#818CF8")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // Teal gradient
        LinearGradient(
            colors: [Color(hex: "#14B8A6"), Color(hex: "#5EEAD4")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ]
    
    // MARK: - Signal Strength Colors
    
    /// Zwraca kolor dla siły sygnału
    static func signalColor(for strength: Int) -> Color {
        switch strength {
        case 0:
            return signalNone
        case 1...2:
            return statusError      // Słaby sygnał - czerwony
        case 3:
            return statusWarning    // Średni sygnał - pomarańczowy
        case 4...5:
            return statusSuccess    // Silny sygnał - zielony
        default:
            return signalNone
        }
    }
    
    // MARK: - Status Colors
    
    /// Kolor dla statusu połączenia
    static let statusConnecting = Color(hex: "#F59E0B")  // Pomarańczowy
    static let statusConnected = Color(hex: "#10B981")   // Zielony
    static let statusDisconnected = Color(hex: "#EF4444") // Czerwony
    static let statusMesh = Color(hex: "#6366F1")        // Indygo
    
    // MARK: - Message Colors
    
    /// Kolory wiadomości na podstawie nadawcy
    static func messageBackgroundColor(isFromCurrentUser: Bool) -> Color {
        isFromCurrentUser ? primary : backgroundSecondary
    }
    
    static func messageTextColor(isFromCurrentUser: Bool) -> Color {
        isFromCurrentUser ? textOnPrimary : textPrimary
    }
    
    // MARK: - Dynamic Colors
    
    /// Kolory adaptujące się do trybu ciemnego/jasnego
    static var adaptiveBackground: Color {
        Color(.systemBackground)
    }
    
    static var adaptiveSecondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var adaptiveTertiaryBackground: Color {
        Color(.tertiarySystemBackground)
    }
}

// MARK: - String Hash Extension

extension String {
    
    /// DJB2 hash algorithm dla konsystentnych kolorów
    var djb2hash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
    
    /// Zwraca hash w zakresie
    func hash(in range: Int) -> Int {
        return abs(djb2hash) % range
    }
}

// MARK: - UIColor Bridge

extension UIColor {
    
    /// Tworzy UIColor z hex stringa
    convenience init(hex: String) {
        self.init(Color(hex: hex))
    }
    
    /// Zwraca hex reprezentację UIColor
    var hexString: String {
        return Color(self).hexString
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension Color {
    
    /// Przykładowe kolory do preview
    static let previewColors: [Color] = [
        Color(hex: "#0263FF"),  // Primary
        Color(hex: "#10B981"),  // Success
        Color(hex: "#F59E0B"),  // Warning
        Color(hex: "#EF4444"),  // Error
        Color(hex: "#6366F1"),  // Mesh
        Color(hex: "#EC4899"),  // Pink
        Color(hex: "#14B8A6"),  // Teal
        Color(hex: "#8B5CF6")   // Purple
    ]
    
    /// Tworzy przykładowy gradient avatara
    static func sampleAvatarGradient() -> LinearGradient {
        return AirLinkColors.avatarGradient(for: "Sample User")
    }
}
#endif
