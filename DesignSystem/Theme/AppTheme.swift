//
//  AppTheme.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - AirLink App Theme

/// Główny motyw aplikacji AirLink
/// Łączy kolory, typografię, spacing i style w jeden spójny system
struct AppTheme {
    
    // MARK: - Theme Configuration
    
    /// Aktualna konfiguracja motywu
    static let current = AppTheme()
    
    // MARK: - Color Palette
    
    let colors = AirLinkColors.self
    
    // MARK: - Typography System
    
    let typography = Typography()
    
    // MARK: - Spacing System
    
    let spacing = Spacing()
    
    // MARK: - Layout System
    
    let layout = Layout()
    
    // MARK: - Shadow System
    
    let shadows = Shadows()
    
    // MARK: - Animation System
    
    let animations = Animations()
    
    // MARK: - Component Styles
    
    let components = ComponentStyles()
}

// MARK: - Typography System

extension AppTheme {
    
    struct Typography {
        
        // MARK: - Text Styles
        
        /// Duże tytuły (np. onboarding, empty states)
        let largeTitle = Font.largeTitle.weight(.bold)
        
        /// Tytuły ekranów
        let title = Font.title.weight(.semibold)
        let title2 = Font.title2.weight(.semibold)
        let title3 = Font.title3.weight(.medium)
        
        /// Nagłówki sekcji
        let headline = Font.headline.weight(.semibold)
        let subheadline = Font.subheadline.weight(.medium)
        
        /// Tekst podstawowy
        let body = Font.body
        let bodyEmphasized = Font.body.weight(.semibold)
        let callout = Font.callout
        
        /// Tekst pomocniczy
        let footnote = Font.footnote
        let caption = Font.caption
        let caption2 = Font.caption2
        
        // MARK: - Specialized Text Styles
        
        /// Style dla wiadomości
        let messageText = Font.body
        let messageTime = Font.caption2.weight(.medium)
        let messageAuthor = Font.caption.weight(.semibold)
        
        /// Style dla UI elementów
        let buttonText = Font.body.weight(.semibold)
        let buttonSmall = Font.callout.weight(.semibold)
        let tabTitle = Font.caption.weight(.medium)
        let navigationTitle = Font.title3.weight(.semibold)
        
        /// Style dla kontaktów
        let contactName = Font.body.weight(.medium)
        let contactStatus = Font.caption
        let avatarLetter = Font.title2.weight(.bold)
        
        /// Style dla ustawień
        let settingsHeader = Font.headline.weight(.semibold)
        let settingsItem = Font.body
        let settingsValue = Font.body.weight(.medium)
        let settingsFooter = Font.footnote
        
        // MARK: - Dynamic Type Support
        
        /// Sprawdza czy użytkownik ma włączone duże czcionki
        var isAccessibilitySize: Bool {
            let category = UIApplication.shared.preferredContentSizeCategory
            return category.isAccessibilityCategory
        }
        
        /// Zwraca odpowiedni rozmiar dla accessibility
        func scaled(_ font: Font) -> Font {
            return font // SwiftUI automatycznie skaluje fonty
        }
    }
}

// MARK: - Spacing System

extension AppTheme {
    
    struct Spacing {
        
        // MARK: - Base Spacing
        
        let xs: CGFloat = AppConstants.Spacing.xs       // 4pt
        let sm: CGFloat = AppConstants.Spacing.sm       // 8pt
        let md: CGFloat = AppConstants.Spacing.md       // 16pt
        let lg: CGFloat = AppConstants.Spacing.lg       // 24pt
        let xl: CGFloat = AppConstants.Spacing.xl       // 32pt
        let xxl: CGFloat = AppConstants.Spacing.xxl     // 48pt
        
        // MARK: - Component Specific Spacing
        
        /// Marginesy ekranów
        let screenMargin: CGFloat = 16
        let screenMarginLarge: CGFloat = 24
        
        /// Padding dla kart i sekcji
        let cardPadding: CGFloat = 16
        let sectionPadding: CGFloat = 20
        
        /// Odstępy między elementami list
        let listItemSpacing: CGFloat = 12
        let listSectionSpacing: CGFloat = 24
        
        /// Padding dla message bubbles
        let messageBubblePadding: CGFloat = 12
        let messageBubbleSpacing: CGFloat = 8
        
        /// Spacing dla form i inputs
        let formSpacing: CGFloat = 16
        let inputPadding: CGFloat = 12
        
        /// Spacing dla Tab Bar i Navigation
        let tabBarPadding: CGFloat = 8
        let navigationPadding: CGFloat = 16
    }
}

// MARK: - Layout System

extension AppTheme {
    
    struct Layout {
        
        // MARK: - Corner Radius
        
        let cornerRadiusSmall: CGFloat = AppConstants.CornerRadius.small         // 8pt
        let cornerRadiusMedium: CGFloat = AppConstants.CornerRadius.medium       // 12pt
        let cornerRadiusLarge: CGFloat = AppConstants.CornerRadius.large         // 16pt
        let cornerRadiusXLarge: CGFloat = AppConstants.CornerRadius.extraLarge   // 24pt
        
        /// Specjalne corner radius
        let messageBubbleRadius: CGFloat = AppConstants.CornerRadius.messageBubble // 18pt
        let avatarRadius: CGFloat = AppConstants.CornerRadius.avatar               // 20pt
        let fabRadius: CGFloat = AppConstants.Sizes.fabSize / 2                   // 28pt
        
        // MARK: - Component Sizes
        
        /// Rozmiary avatarów
        let avatarSmall: CGFloat = AppConstants.Sizes.avatarSmall       // 32pt
        let avatarMedium: CGFloat = AppConstants.Sizes.avatarMedium     // 40pt
        let avatarLarge: CGFloat = AppConstants.Sizes.avatarLarge       // 60pt
        let avatarXLarge: CGFloat = AppConstants.Sizes.avatarExtraLarge // 80pt
        
        /// Rozmiary przycisków
        let buttonHeight: CGFloat = 44
        let buttonHeightSmall: CGFloat = 32
        let buttonHeightLarge: CGFloat = 50
        
        /// Rozmiary input fields
        let inputHeight: CGFloat = AppConstants.Sizes.messageInputHeight // 44pt
        let inputHeightMultiline: CGFloat = 100
        
        /// Rozmiary ikon
        let iconSmall: CGFloat = AppConstants.Sizes.iconSmall   // 16pt
        let iconMedium: CGFloat = AppConstants.Sizes.iconMedium // 20pt
        let iconLarge: CGFloat = AppConstants.Sizes.iconLarge   // 24pt
        
        /// FAB
        let fabSize: CGFloat = AppConstants.Sizes.fabSize // 56pt
        
        // MARK: - Signal Indicator
        
        let signalBarWidth: CGFloat = AppConstants.Sizes.signalBarWidth
        let signalBarMaxHeight: CGFloat = AppConstants.Sizes.signalBarMaxHeight
        let signalBarSpacing: CGFloat = AppConstants.Sizes.signalBarSpacing
        
        // MARK: - Layout Helpers
        
        /// Minimalne touch target size (iOS HIG)
        let minTouchTarget: CGFloat = 44
        
        /// Maksymalna szerokość dla message bubbles
        let maxMessageWidth: CGFloat = 280
        
        /// Szerokość ekranów na iPadzie
        let maxContentWidth: CGFloat = 400
    }
}

// MARK: - Shadow System

extension AppTheme {
    
    struct Shadows {
        
        // MARK: - Elevation Levels
        
        /// Cień dla elementów na powierzchni (buttons, cards)
        let elevation1 = Shadow(
            color: AirLinkColors.shadowLight,
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// Cień dla uniesionych elementów (FAB, sheets)
        let elevation2 = Shadow(
            color: AirLinkColors.shadowMedium,
            radius: 4,
            x: 0,
            y: 2
        )
        
        /// Cień dla modal i overlay
        let elevation3 = Shadow(
            color: AirLinkColors.shadowHeavy,
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// Specjalne cienie
        let fabShadow = Shadow(
            color: AirLinkColors.primary.opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
        
        let messageBubbleShadow = Shadow(
            color: AirLinkColors.shadowLight,
            radius: 1,
            x: 0,
            y: 0.5
        )
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Animation System

extension AppTheme {
    
    struct Animations {
        
        // MARK: - Basic Animations
        
        let fast = AppConstants.Animation.fast           // 0.2s
        let medium = AppConstants.Animation.medium       // 0.3s
        let slow = AppConstants.Animation.slow           // 0.5s
        
        // MARK: - Spring Animations
        
        let spring = Animation.spring(response: 0.6, dampingFraction: 0.8)
        let springFast = Animation.spring(response: 0.4, dampingFraction: 0.7)
        let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
        
        // MARK: - Component Specific
        
        let messageBubble = AppConstants.Animation.messageBubble
        let fab = AppConstants.Animation.fab
        let signalUpdate = AppConstants.Animation.signalUpdate
        
        // MARK: - Transition Animations
        
        let slideIn = AnyTransition.move(edge: .trailing)
        let slideOut = AnyTransition.move(edge: .leading)
        let fadeIn = AnyTransition.opacity
        let scaleIn = AnyTransition.scale.combined(with: .opacity)
        
        // MARK: - Loading Animations
        
        let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        let rotate = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    }
}

// MARK: - Component Styles

extension AppTheme {
    
    struct ComponentStyles {
        
        // MARK: - Button Styles
        
        let primaryButton = ButtonStyle.primary
        let secondaryButton = ButtonStyle.secondary
        let tertiaryButton = ButtonStyle.tertiary
        let destructiveButton = ButtonStyle.destructive
        
        // MARK: - Card Styles
        
        let card = CardStyle.default
        let elevatedCard = CardStyle.elevated
        
        // MARK: - List Styles
        
        let listRow = ListRowStyle.default
        let listRowSelected = ListRowStyle.selected
    }
}

// MARK: - Button Styles

extension ButtonStyle {
    
    static let primary = PrimaryButtonStyle()
    static let secondary = SecondaryButtonStyle()
    static let tertiary = TertiaryButtonStyle()
    static let destructive = DestructiveButtonStyle()
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(AirLinkColors.buttonPrimaryText)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .background(
                configuration.isPressed
                ? AirLinkColors.buttonPrimaryPressed
                : AirLinkColors.buttonPrimary
            )
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(AirLinkColors.buttonSecondaryText)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .background(
                configuration.isPressed
                ? AirLinkColors.buttonSecondaryPressed
                : AirLinkColors.buttonSecondary
            )
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(AirLinkColors.buttonTertiaryText)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .background(AirLinkColors.buttonTertiary)
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(AirLinkColors.buttonDestructiveText)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .background(
                configuration.isPressed
                ? AirLinkColors.buttonDestructivePressed
                : AirLinkColors.buttonDestructive
            )
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
}

// MARK: - Card Styles

struct CardStyle {
    static let `default` = DefaultCardStyle()
    static let elevated = ElevatedCardStyle()
}

struct DefaultCardStyle {
    func apply<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(AirLinkColors.backgroundCard)
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
    }
}

struct ElevatedCardStyle {
    func apply<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(AirLinkColors.backgroundCard)
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .shadow(
                color: AppTheme.current.shadows.elevation2.color,
                radius: AppTheme.current.shadows.elevation2.radius,
                x: AppTheme.current.shadows.elevation2.x,
                y: AppTheme.current.shadows.elevation2.y
            )
    }
}

// MARK: - List Row Styles

struct ListRowStyle {
    static let `default` = DefaultListRowStyle()
    static let selected = SelectedListRowStyle()
}

struct DefaultListRowStyle {
    func apply<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .listRowBackground(AirLinkColors.listRowBackground)
            .listRowSeparator(.visible, edges: .bottom)
            .listRowSeparatorTint(AirLinkColors.listSeparator)
    }
}

struct SelectedListRowStyle {
    func apply<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .listRowBackground(AirLinkColors.listRowBackgroundSelected)
            .listRowSeparator(.visible, edges: .bottom)
            .listRowSeparatorTint(AirLinkColors.listSeparator)
    }
}

// MARK: - Environment Integration

extension EnvironmentValues {
    
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.current
}

// MARK: - View Extensions

extension View {
    
    /// Stosuje główny motyw aplikacji
    func withAppTheme() -> some View {
        self.environment(\.appTheme, AppTheme.current)
    }
    
    /// Stosuje default card style
    func defaultCard() -> some View {
        AppTheme.current.components.card.apply {
            self.padding(AppTheme.current.spacing.cardPadding)
        }
    }
    
    /// Stosuje elevated card style
    func elevatedCard() -> some View {
        AppTheme.current.components.elevatedCard.apply {
            self.padding(AppTheme.current.spacing.cardPadding)
        }
    }
}
