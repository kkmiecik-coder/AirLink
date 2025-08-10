//
//  ButtonStyles.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - AirLink Button Styles

/// Kolekcja wszystkich stylów przycisków używanych w AirLink
struct AirLinkButtonStyles {
    
    // MARK: - Main Button Styles
    
    static let primary = AirLinkPrimaryButtonStyle()
    static let secondary = AirLinkSecondaryButtonStyle()
    static let tertiary = AirLinkTertiaryButtonStyle()
    static let destructive = AirLinkDestructiveButtonStyle()
    
    // MARK: - Specialized Button Styles
    
    static let fab = AirLinkFABStyle()
    static let pill = AirLinkPillButtonStyle()
    static let icon = AirLinkIconButtonStyle()
    static let compact = AirLinkCompactButtonStyle()
    static let outline = AirLinkOutlineButtonStyle()
    static let ghost = AirLinkGhostButtonStyle()
}

// MARK: - Primary Button Style

struct AirLinkPrimaryButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(AirLinkColors.buttonPrimaryText)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
    
    private func buttonBackground(isPressed: Bool) -> Color {
        if !isEnabled {
            return AirLinkColors.buttonSecondary
        }
        return isPressed ? AirLinkColors.buttonPrimaryPressed : AirLinkColors.buttonPrimary
    }
}

// MARK: - Secondary Button Style

struct AirLinkSecondaryButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(buttonTextColor(isPressed: configuration.isPressed))
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
    
    private func buttonBackground(isPressed: Bool) -> Color {
        if !isEnabled {
            return AirLinkColors.buttonSecondary.opacity(0.5)
        }
        return isPressed ? AirLinkColors.buttonSecondaryPressed : AirLinkColors.buttonSecondary
    }
    
    private func buttonTextColor(isPressed: Bool) -> Color {
        return isEnabled ? AirLinkColors.buttonSecondaryText : AirLinkColors.textTertiary
    }
}

// MARK: - Tertiary Button Style

struct AirLinkTertiaryButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(buttonTextColor)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .background(AirLinkColors.buttonTertiary)
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1.0 : 0.6))
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
    
    private var buttonTextColor: Color {
        return isEnabled ? AirLinkColors.buttonTertiaryText : AirLinkColors.textTertiary
    }
}

// MARK: - Destructive Button Style

struct AirLinkDestructiveButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(AirLinkColors.buttonDestructiveText)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
    
    private func buttonBackground(isPressed: Bool) -> Color {
        if !isEnabled {
            return AirLinkColors.statusError.opacity(0.5)
        }
        return isPressed ? AirLinkColors.buttonDestructivePressed : AirLinkColors.buttonDestructive
    }
}

// MARK: - FAB (Floating Action Button) Style

struct AirLinkFABStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.semibold))
            .foregroundColor(AirLinkColors.fabIcon)
            .frame(width: AppTheme.current.layout.fabSize, height: AppTheme.current.layout.fabSize)
            .background(AirLinkColors.fabBackground)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .shadow(
                color: AppTheme.current.shadows.fabShadow.color,
                radius: AppTheme.current.shadows.fabShadow.radius,
                x: AppTheme.current.shadows.fabShadow.x,
                y: AppTheme.current.shadows.fabShadow.y
            )
            .animation(AppTheme.current.animations.fab, value: configuration.isPressed)
    }
}

// MARK: - Pill Button Style

struct AirLinkPillButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonSmall)
            .foregroundColor(buttonTextColor(isPressed: configuration.isPressed))
            .padding(.horizontal, AppTheme.current.spacing.md)
            .padding(.vertical, AppTheme.current.spacing.sm)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .cornerRadius(AppTheme.current.layout.buttonHeightSmall / 2) // Pill shape
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
    
    private func buttonBackground(isPressed: Bool) -> Color {
        if !isEnabled {
            return AirLinkColors.buttonSecondary.opacity(0.5)
        }
        return isPressed ? AirLinkColors.primaryOpacity20 : AirLinkColors.primaryOpacity10
    }
    
    private func buttonTextColor(isPressed: Bool) -> Color {
        return isEnabled ? AirLinkColors.primary : AirLinkColors.textTertiary
    }
}

// MARK: - Icon Button Style

struct AirLinkIconButtonStyle: ButtonStyle {
    
    var size: CGFloat = AppTheme.current.layout.buttonHeight
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundColor(AirLinkColors.textSecondary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(configuration.isPressed ? AirLinkColors.buttonSecondaryPressed : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
}

// MARK: - Compact Button Style

struct AirLinkCompactButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonSmall)
            .foregroundColor(AirLinkColors.buttonPrimaryText)
            .padding(.horizontal, AppTheme.current.spacing.sm)
            .frame(height: AppTheme.current.layout.buttonHeightSmall)
            .background(
                configuration.isPressed
                ? AirLinkColors.buttonPrimaryPressed
                : AirLinkColors.buttonPrimary
            )
            .cornerRadius(AppTheme.current.layout.cornerRadiusSmall)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
}

// MARK: - Outline Button Style

struct AirLinkOutlineButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(buttonTextColor)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                    .fill(configuration.isPressed ? AirLinkColors.primaryOpacity10 : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
    
    private var buttonTextColor: Color {
        return isEnabled ? AirLinkColors.primary : AirLinkColors.textTertiary
    }
    
    private var borderColor: Color {
        return isEnabled ? AirLinkColors.primary : AirLinkColors.borderSecondary
    }
}

// MARK: - Ghost Button Style

struct AirLinkGhostButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(buttonTextColor)
            .padding(.horizontal, AppTheme.current.spacing.md)
            .frame(height: AppTheme.current.layout.buttonHeight)
            .background(
                configuration.isPressed
                ? AirLinkColors.primaryOpacity10
                : Color.clear
            )
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(AppTheme.current.animations.fast, value: configuration.isPressed)
    }
    
    private var buttonTextColor: Color {
        return isEnabled ? AirLinkColors.primary : AirLinkColors.textTertiary
    }
}

// MARK: - Button Extensions

extension Button {
    
    /// Stosuje primary button style
    func primaryStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.primary)
    }
    
    /// Stosuje secondary button style
    func secondaryStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.secondary)
    }
    
    /// Stosuje tertiary button style
    func tertiaryStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.tertiary)
    }
    
    /// Stosuje destructive button style
    func destructiveStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.destructive)
    }
    
    /// Stosuje FAB style
    func fabStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.fab)
    }
    
    /// Stosuje pill button style
    func pillStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.pill)
    }
    
    /// Stosuje icon button style
    func iconStyle(size: CGFloat = AppTheme.current.layout.buttonHeight) -> some View {
        self.buttonStyle(AirLinkIconButtonStyle(size: size))
    }
    
    /// Stosuje compact button style
    func compactStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.compact)
    }
    
    /// Stosuje outline button style
    func outlineStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.outline)
    }
    
    /// Stosuje ghost button style
    func ghostStyle() -> some View {
        self.buttonStyle(AirLinkButtonStyles.ghost)
    }
}
