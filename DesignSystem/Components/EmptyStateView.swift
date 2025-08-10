//
//  EmptyStateView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - EmptyStateView Component

/// Uniwersalny komponent dla stanów pustych (empty states)
/// Wyświetla ikonę, tytuł, opis i opcjonalny przycisk akcji
struct EmptyStateView: View {
    
    // MARK: - Properties
    
    let icon: String
    let title: String
    let description: String?
    let actionTitle: String?
    let actionIcon: String?
    let style: EmptyStateStyle
    let action: (() -> Void)?
    
    // MARK: - Initializers
    
    init(
        icon: String,
        title: String,
        description: String? = nil,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        style: EmptyStateStyle = .standard,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.style = style
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: style.spacing) {
            
            // Icon
            iconView
            
            // Text content
            textContent
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                actionButton(title: actionTitle, action: action)
            }
        }
        .frame(maxWidth: style.maxWidth)
        .padding(style.padding)
        .multilineTextAlignment(.center)
    }
    
    // MARK: - Icon View
    
    private var iconView: some View {
        ZStack {
            // Background circle (for some styles)
            if style.hasIconBackground {
                Circle()
                    .fill(style.iconBackgroundColor)
                    .frame(width: style.iconBackgroundSize, height: style.iconBackgroundSize)
            }
            
            // Icon
            Image(systemName: icon)
                .font(style.iconFont)
                .foregroundColor(style.iconColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    // MARK: - Text Content
    
    private var textContent: some View {
        VStack(spacing: AppTheme.current.spacing.sm) {
            // Title
            Text(title)
                .modifier(style.titleStyle)
            
            // Description
            if let description = description {
                Text(description)
                    .modifier(style.descriptionStyle)
            }
        }
    }
    
    // MARK: - Action Button
    
    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.current.spacing.xs) {
                if let actionIcon = actionIcon {
                    Image(systemName: actionIcon)
                        .font(style.actionIconFont)
                }
                
                Text(title)
                    .font(style.actionFont)
            }
            .foregroundColor(style.actionColor)
            .padding(.horizontal, style.actionPadding.horizontal)
            .padding(.vertical, style.actionPadding.vertical)
            .background(style.actionBackground)
            .cornerRadius(style.actionCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style.actionCornerRadius)
                    .stroke(style.actionBorderColor, lineWidth: style.actionBorderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State Style

enum EmptyStateStyle {
    case standard      // Standardowy empty state
    case compact       // Mniejszy, bardziej kompaktowy
    case prominent     // Duży, dla głównych empty states
    case minimal       // Minimalny, tylko tekst
    case illustrated   // Z kolorową ilustracją
    case error         // Dla stanów błędu
    case success       // Dla stanów sukcesu (np. "Wszystko skończone!")
    
    var spacing: CGFloat {
        switch self {
        case .standard, .illustrated, .error, .success:
            return AppTheme.current.spacing.lg
        case .compact, .minimal:
            return AppTheme.current.spacing.md
        case .prominent:
            return AppTheme.current.spacing.xl
        }
    }
    
    var maxWidth: CGFloat {
        switch self {
        case .standard, .error, .success:
            return 280
        case .compact, .minimal:
            return 240
        case .prominent, .illustrated:
            return 320
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .standard, .illustrated:
            return EdgeInsets(top: 32, leading: 24, bottom: 32, trailing: 24)
        case .compact:
            return EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16)
        case .prominent:
            return EdgeInsets(top: 48, leading: 32, bottom: 48, trailing: 32)
        case .minimal:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .error, .success:
            return EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        }
    }
    
    var iconFont: Font {
        switch self {
        case .standard, .illustrated:
            return .system(size: 48, weight: .light)
        case .compact:
            return .system(size: 32, weight: .light)
        case .prominent:
            return .system(size: 64, weight: .light)
        case .minimal:
            return .system(size: 24, weight: .light)
        case .error, .success:
            return .system(size: 40, weight: .medium)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .standard, .compact, .minimal:
            return AirLinkColors.textTertiary
        case .prominent:
            return AirLinkColors.textSecondary
        case .illustrated:
            return AirLinkColors.primary
        case .error:
            return AirLinkColors.statusError
        case .success:
            return AirLinkColors.statusSuccess
        }
    }
    
    var hasIconBackground: Bool {
        switch self {
        case .illustrated, .error, .success:
            return true
        case .standard, .compact, .prominent, .minimal:
            return false
        }
    }
    
    var iconBackgroundColor: Color {
        switch self {
        case .illustrated:
            return AirLinkColors.primaryOpacity10
        case .error:
            return AirLinkColors.statusError.opacity(0.1)
        case .success:
            return AirLinkColors.statusSuccess.opacity(0.1)
        default:
            return Color.clear
        }
    }
    
    var iconBackgroundSize: CGFloat {
        switch self {
        case .illustrated, .error, .success:
            return 80
        default:
            return 0
        }
    }
    
    var titleStyle: some ViewModifier {
        switch self {
        case .standard, .illustrated:
            return AirLinkTextStyles.title3
        case .compact:
            return AirLinkTextStyles.headline
        case .prominent:
            return AirLinkTextStyles.title2
        case .minimal:
            return AirLinkTextStyles.body
        case .error, .success:
            return AirLinkTextStyles.title3
        }
    }
    
    var descriptionStyle: some ViewModifier {
        switch self {
        case .standard, .illustrated, .error, .success:
            return AirLinkTextStyles.body
        case .compact, .minimal:
            return AirLinkTextStyles.callout
        case .prominent:
            return AirLinkTextStyles.title3
        }
    }
    
    var actionFont: Font {
        switch self {
        case .standard, .compact, .illustrated, .error, .success:
            return AppTheme.current.typography.buttonText
        case .prominent:
            return AppTheme.current.typography.buttonText
        case .minimal:
            return AppTheme.current.typography.callout.weight(.semibold)
        }
    }
    
    var actionIconFont: Font {
        return .callout.weight(.semibold)
    }
    
    var actionColor: Color {
        switch self {
        case .standard, .compact, .illustrated, .minimal:
            return AirLinkColors.buttonPrimaryText
        case .prominent:
            return AirLinkColors.buttonPrimaryText
        case .error:
            return AirLinkColors.buttonDestructiveText
        case .success:
            return .white
        }
    }
    
    var actionBackground: Color {
        switch self {
        case .standard, .compact, .illustrated, .prominent, .minimal:
            return AirLinkColors.buttonPrimary
        case .error:
            return AirLinkColors.buttonDestructive
        case .success:
            return AirLinkColors.statusSuccess
        }
    }
    
    var actionBorderColor: Color {
        return Color.clear
    }
    
    var actionBorderWidth: CGFloat {
        return 0
    }
    
    var actionCornerRadius: CGFloat {
        switch self {
        case .minimal:
            return 8
        default:
            return AppTheme.current.layout.cornerRadiusMedium
        }
    }
    
    var actionPadding: (horizontal: CGFloat, vertical: CGFloat) {
        switch self {
        case .standard, .illustrated, .error, .success:
            return (24, 12)
        case .compact:
            return (20, 10)
        case .prominent:
            return (32, 16)
        case .minimal:
            return (16, 8)
        }
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    
    // MARK: - Chat Empty States
    
    /// Brak rozmów na ekranie głównym
    static func noChats(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "message",
            title: AppConstants.UIText.noChatsTitle,
            description: AppConstants.UIText.noChatsSubtitle,
            actionTitle: "Rozpocznij czat",
            actionIcon: AppConstants.Icons.add,
            style: .standard,
            action: action
        )
    }
    
    /// Brak kontaktów
    static func noContacts(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "person.2",
            title: AppConstants.UIText.noContactsTitle,
            description: AppConstants.UIText.noContactsSubtitle,
            actionTitle: "Skanuj kod QR",
            actionIcon: AppConstants.Icons.qrScanner,
            style: .illustrated,
            action: action
        )
    }
    
    /// Brak wiadomości w czacie
    static func noMessages() -> EmptyStateView {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "Rozpocznij rozmowę",
            description: "Wyślij pierwszą wiadomość aby rozpocząć czat",
            style: .compact
        )
    }
    
    // MARK: - Connection Empty States
    
    /// Brak połączenia Bluetooth
    static func bluetoothOff(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "bluetooth.slash",
            title: AppConstants.UIText.bluetoothOffTitle,
            description: AppConstants.UIText.bluetoothOffMessage,
            actionTitle: "Otwórz Ustawienia",
            actionIcon: "gearshape",
            style: .error,
            action: action
        )
    }
    
    /// Szukanie urządzeń
    static func searching() -> EmptyStateView {
        EmptyStateView(
            icon: "antenna.radiowaves.left.and.right",
            title: AppConstants.UIText.searchingTitle,
            description: AppConstants.UIText.searchingMessage,
            style: .compact
        )
    }
    
    /// Brak dostępnych urządzeń
    static func noDevicesFound(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Brak urządzeń",
            description: "Nie znaleziono innych urządzeń w pobliżu. Upewnij się, że inne osoby mają włączoną aplikację.",
            actionTitle: "Szukaj ponownie",
            actionIcon: "arrow.clockwise",
            style: .standard,
            action: action
        )
    }
    
    // MARK: - Permission Empty States
    
    /// Brak uprawnień do kamery
    static func cameraPermission(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "camera",
            title: AppConstants.UIText.cameraPermissionTitle,
            description: AppConstants.UIText.cameraPermissionMessage,
            actionTitle: "Przejdź do Ustawień",
            actionIcon: "gear",
            style: .error,
            action: action
        )
    }
    
    /// Brak uprawnień do zdjęć
    static func photosPermission(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "photo",
            title: AppConstants.UIText.photosPermissionTitle,
            description: AppConstants.UIText.photosPermissionMessage,
            actionTitle: "Przejdź do Ustawień",
            actionIcon: "gear",
            style: .error,
            action: action
        )
    }
    
    // MARK: - Success States
    
    /// Wszystkie wiadomości przeczytane
    static func allCaughtUp() -> EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "Wszystko przeczytane!",
            description: "Nie masz nowych wiadomości",
            style: .success
        )
    }
    
    /// Kontakt dodany pomyślnie
    static func contactAdded() -> EmptyStateView {
        EmptyStateView(
            icon: "person.badge.plus",
            title: "Kontakt dodany!",
            description: "Możesz teraz rozpocząć rozmowę",
            style: .success
        )
    }
    
    // MARK: - Generic States
    
    /// Ogólny stan ładowania
    static func loading(message: String = "Ładowanie...") -> EmptyStateView {
        EmptyStateView(
            icon: "arrow.triangle.2.circlepath",
            title: message,
            style: .minimal
        )
    }
    
    /// Ogólny błąd
    static func error(
        title: String = "Wystąpił błąd",
        description: String = "Spróbuj ponownie za chwilę",
        action: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: title,
            description: description,
            actionTitle: "Spróbuj ponownie",
            actionIcon: "arrow.clockwise",
            style: .error,
            action: action
        )
    }
}

// MARK: - View Extensions

extension View {
    
    /// Wyświetla empty state gdy warunek jest spełniony
    func emptyState<EmptyContent: View>(
        when condition: Bool,
        @ViewBuilder content: () -> EmptyContent
    ) -> some View {
        ZStack {
            self
                .opacity(condition ? 0 : 1)
            
            if condition {
                content()
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(AppTheme.current.animations.medium, value: condition)
    }
    
    /// Wyświetla empty state dla pustej kolekcji
    func emptyState<T, EmptyContent: View>(
        for collection: [T],
        @ViewBuilder content: () -> EmptyContent
    ) -> some View {
        self.emptyState(when: collection.isEmpty, content: content)
    }
}

// MARK: - Preview

#Preview("Empty State Variants") {
    ScrollView {
        VStack(spacing: 32) {
            
            // Chat states
            Group {
                EmptyStateView.noChats {}
                Divider()
                EmptyStateView.noContacts {}
                Divider()
                EmptyStateView.noMessages()
            }
            
            // Connection states
            Group {
                Divider()
                EmptyStateView.bluetoothOff {}
                Divider()
                EmptyStateView.searching()
                Divider()
                EmptyStateView.noDevicesFound {}
            }
            
            // Permission states
            Group {
                Divider()
                EmptyStateView.cameraPermission {}
                Divider()
                EmptyStateView.photosPermission {}
            }
            
            // Success states
            Group {
                Divider()
                EmptyStateView.allCaughtUp()
                Divider()
                EmptyStateView.contactAdded()
            }
        }
        .padding()
    }
    .background(AirLinkColors.background)
}

#Preview("Empty State Styles") {
    let styles: [(EmptyStateStyle, String)] = [
        (.standard, "Standard"),
        (.compact, "Compact"),
        (.prominent, "Prominent"),
        (.minimal, "Minimal"),
        (.illustrated, "Illustrated"),
        (.error, "Error"),
        (.success, "Success")
    ]
    
    return ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
            ForEach(Array(styles.enumerated()), id: \.offset) { index, style in
                VStack {
                    EmptyStateView(
                        icon: "star",
                        title: style.1,
                        description: "Przykładowy opis dla stylu \(style.1.lowercased())",
                        actionTitle: "Akcja",
                        style: style.0
                    ) {}
                    
                    Text(style.1)
                        .caption1Style()
                }
            }
        }
        .padding()
    }
    .background(AirLinkColors.background)
}
