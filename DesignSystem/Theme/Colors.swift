//
//  Colors.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - AirLink Design System Colors

/// Semantic color system dla AirLink
/// Używa AppConstants.Colors jako podstawy i rozszerza o semantic meanings
struct AirLinkColors {
    
    // MARK: - Primary Colors
    
    /// Główny kolor marki - #0263FF
    static let primary = AppConstants.Colors.accent
    static let primaryLight = AppConstants.Colors.accentLight
    static let primaryDark = AppConstants.Colors.accentDark
    
    /// Kolor primary z przezroczystością
    static let primaryOpacity10 = primary.opacity(0.1)
    static let primaryOpacity20 = primary.opacity(0.2)
    static let primaryOpacity50 = primary.opacity(0.5)
    
    // MARK: - Background Colors
    
    /// Tła adaptywne do Light/Dark mode
    static let background = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    static let backgroundQuaternary = Color(.quaternarySystemBackground)
    
    /// Tła dla grup i sekcji
    static let backgroundGrouped = Color(.systemGroupedBackground)
    static let backgroundGroupedSecondary = Color(.secondarySystemGroupedBackground)
    static let backgroundGroupedTertiary = Color(.tertiarySystemGroupedBackground)
    
    /// Tła dla elevated components (cards, sheets)
    static let backgroundElevated = background
    static let backgroundCard = backgroundSecondary
    
    // MARK: - Text Colors
    
    /// Kolory tekstu adaptywne
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let textQuaternary = Color(.quaternaryLabel)
    
    /// Kolory tekstu na kolorowych tłach
    static let textOnPrimary = Color.white
    static let textOnDark = Color.white
    static let textOnLight = Color.black
    
    // MARK: - Interactive Colors
    
    /// Kolory dla przycisków
    static let buttonPrimary = primary
    static let buttonSecondary = Color(.systemGray5)
    static let buttonTertiary = Color.clear
    static let buttonDestructive = Color(.systemRed)
    
    /// Kolory tekstu na przyciskach
    static let buttonPrimaryText = textOnPrimary
    static let buttonSecondaryText = textPrimary
    static let buttonTertiaryText = primary
    static let buttonDestructiveText = Color.white
    
    /// Stany przycisków
    static let buttonPrimaryPressed = primaryDark
    static let buttonSecondaryPressed = Color(.systemGray4)
    static let buttonDestructivePressed = Color(.systemRed).opacity(0.8)
    
    // MARK: - Chat Colors
    
    /// Kolory message bubbles
    static let myMessageBackground = primary
    static let myMessageText = textOnPrimary
    static let otherMessageBackground = Color(.systemGray5)
    static let otherMessageText = textPrimary
    static let systemMessageText = textSecondary
    
    /// Kolory dla różnych typów wiadomości
    static let messageTimestamp = textTertiary
    static let messageStatus = textSecondary
    static let messageError = Color(.systemRed)
    
    // MARK: - Status Colors
    
    /// Kolory połączeń i statusów
    static let statusOnline = Color(.systemGreen)
    static let statusOffline = Color(.systemGray3)
    static let statusMesh = Color(.systemBlue)
    static let statusConnecting = Color(.systemOrange)
    static let statusError = Color(.systemRed)
    static let statusWarning = Color(.systemOrange)
    static let statusSuccess = Color(.systemGreen)
    
    // MARK: - Signal Strength Colors
    
    /// Kolory dla wskaźnika siły sygnału (0-5 kresek)
    static let signalNone = Color(.systemGray4)      // 0 kresek
    static let signalWeak = Color(.systemRed)        // 1-2 kreski
    static let signalMedium = Color(.systemOrange)   // 3 kreski
    static let signalStrong = Color(.systemGreen)    // 4-5 kresek
    
    /// Helper function dla koloru sygnału
    static func signalColor(for strength: Int) -> Color {
        switch strength {
        case 0:
            return signalNone
        case 1...2:
            return signalWeak
        case 3:
            return signalMedium
        case 4...5:
            return signalStrong
        default:
            return signalNone
        }
    }
    
    // MARK: - Border Colors
    
    /// Kolory obramowań
    static let border = Color(.separator)
    static let borderSecondary = Color(.secondaryLabel).opacity(0.2)
    static let borderTertiary = Color(.tertiaryLabel).opacity(0.1)
    
    /// Kolory obramowań dla focusowanych elementów
    static let borderFocused = primary
    static let borderError = statusError
    static let borderSuccess = statusSuccess
    
    // MARK: - Avatar Colors
    
    /// Kolory dla domyślnych avatarów (gradients)
    static let avatarColors: [Color] = [
        Color(hex: "#FF6B6B"), // Czerwony
        Color(hex: "#4ECDC4"), // Turkusowy
        Color(hex: "#45B7D1"), // Niebieski
        Color(hex: "#96CEB4"), // Zielony
        Color(hex: "#FFEAA7"), // Żółty
        Color(hex: "#DDA0DD"), // Fioletowy
        Color(hex: "#98D8C8"), // Miętowy
        Color(hex: "#FDCB6E"), // Pomarańczowy
        Color(hex: "#6C5CE7"), // Indygo
        Color(hex: "#A29BFE")  // Lawendowy
    ]
    
    /// Pobiera kolor avatara na podstawie tekstu (consistent hashing)
    static func avatarColor(for text: String) -> Color {
        let hash = abs(text.hashValue)
        let index = hash % avatarColors.count
        return avatarColors[index]
    }
    
    /// Gradient dla avatara na podstawie tekstu
    static func avatarGradient(for text: String) -> LinearGradient {
        let baseColor = avatarColor(for: text)
        let lighterColor = baseColor.opacity(0.7)
        
        return LinearGradient(
            colors: [lighterColor, baseColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Shadow Colors
    
    /// Kolory cieni
    static let shadowLight = Color.black.opacity(0.1)
    static let shadowMedium = Color.black.opacity(0.2)
    static let shadowHeavy = Color.black.opacity(0.3)
    
    // MARK: - Overlay Colors
    
    /// Kolory nakładek
    static let overlayLight = Color.black.opacity(0.2)
    static let overlayMedium = Color.black.opacity(0.4)
    static let overlayHeavy = Color.black.opacity(0.6)
    
    /// Kolory dla modal backgrounds
    static let modalBackground = Color.black.opacity(0.3)
    static let sheetBackground = backgroundElevated
    
    // MARK: - Tab Bar Colors
    
    /// Kolory dla tab bara
    static let tabBarBackground = backgroundElevated
    static let tabBarSelected = primary
    static let tabBarUnselected = textSecondary
    
    // MARK: - Navigation Colors
    
    /// Kolory dla navigation bara
    static let navigationBackground = backgroundElevated
    static let navigationTitle = textPrimary
    static let navigationButton = primary
    
    // MARK: - List Colors
    
    /// Kolory dla list i rows
    static let listBackground = background
    static let listRowBackground = backgroundElevated
    static let listRowBackgroundSelected = primaryOpacity10
    static let listSeparator = border
    
    // MARK: - Input Colors
    
    /// Kolory dla input fields
    static let inputBackground = backgroundSecondary
    static let inputBorder = borderSecondary
    static let inputBorderFocused = borderFocused
    static let inputText = textPrimary
    static let inputPlaceholder = textTertiary
    
    // MARK: - FAB Colors
    
    /// Kolory dla Floating Action Button
    static let fabBackground = primary
    static let fabIcon = textOnPrimary
    static let fabShadow = shadowMedium
    
    // MARK: - QR Colors
    
    /// Kolory dla QR kodów
    static let qrForeground = textPrimary
    static let qrBackground = background
    static let qrViewfinderOverlay = overlayMedium
    static let qrViewfinderFrame = primary
}

// MARK: - Environment Key

/// Environment key dla dostępu do kolorów w całej aplikacji
struct ColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
    var colorScheme: ColorScheme? {
        get { self[ColorSchemeKey.self] }
        set { self[ColorSchemeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    
    /// Stosuje semantic color z automatyczną adaptacją do color scheme
    func semanticForegroundColor(_ color: Color) -> some View {
        self.foregroundColor(color)
    }
    
    /// Stosuje semantic background color
    func semanticBackgroundColor(_ color: Color) -> some View {
        self.background(color)
    }
    
    /// Stosuje primary gradient background
    func primaryGradientBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [AirLinkColors.primary, AirLinkColors.primaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    /// Stosuje avatar gradient dla tekstu
    func avatarGradientBackground(for text: String) -> some View {
        self.background(AirLinkColors.avatarGradient(for: text))
    }
}

// MARK: - Color Extension

extension Color {
    
    /// Zwraca kolor dostosowany do jasności tła
    func adapted(for colorScheme: ColorScheme) -> Color {
        return self
    }
    
    /// Zwraca kolor z przeźroczystością
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
    
    /// Sprawdza czy kolor jest jasny czy ciemny
    var isLight: Bool {
        // Uproszczone sprawdzenie - można rozszerzyć
        return true // Placeholder - w rzeczywistości trzeba by analizować składowe RGB
    }
}
