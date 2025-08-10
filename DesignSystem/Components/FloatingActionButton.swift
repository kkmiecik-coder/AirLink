//
//  FloatingActionButton.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - FloatingActionButton Component

/// Floating Action Button (FAB) dla AirLink
/// Główny przycisk akcji w prawym dolnym rogu ekranu
struct FloatingActionButton: View {
    
    // MARK: - Properties
    
    let icon: String
    let action: () -> Void
    let style: FABStyle
    let isVisible: Bool
    let hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle
    
    // MARK: - State
    
    @State private var isPressed = false
    @State private var isPulsing = false
    
    // MARK: - Initializers
    
    init(
        icon: String = AppConstants.Icons.add,
        style: FABStyle = .primary,
        isVisible: Bool = true,
        hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.isVisible = isVisible
        self.hapticFeedback = hapticFeedback
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: handleTap) {
            buttonContent
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? (isPressed ? 0.9 : 1.0) : 0.0)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(AppTheme.current.animations.fab, value: isVisible)
        .animation(AppTheme.current.animations.fast, value: isPressed)
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: shadowOffset
        )
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
    
    // MARK: - Button Content
    
    private var buttonContent: some View {
        ZStack {
            // Background
            Circle()
                .fill(backgroundGradient)
                .frame(width: style.size, height: style.size)
                .overlay(
                    Circle()
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                        .opacity(style.hasBorder ? 1.0 : 0.0)
                )
            
            // Icon
            Image(systemName: icon)
                .font(style.iconFont)
                .foregroundColor(style.iconColor)
                .rotationEffect(.degrees(isPulsing ? 180 : 0))
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.6).repeatCount(1),
                    value: isPulsing
                )
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundGradient: some ShapeStyle {
        if style.hasGradient {
            return LinearGradient(
                colors: style.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return style.backgroundColor
        }
    }
    
    private var shadowColor: Color {
        return style.shadowColor.opacity(isVisible ? 1.0 : 0.0)
    }
    
    private var shadowRadius: CGFloat {
        return isPressed ? style.shadowRadius * 0.5 : style.shadowRadius
    }
    
    private var shadowOffset: CGFloat {
        return isPressed ? style.shadowOffset * 0.5 : style.shadowOffset
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        // Haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: hapticFeedback)
        impactGenerator.impactOccurred()
        
        // Pulse animation
        withAnimation {
            isPulsing = true
        }
        
        // Reset pulse after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isPulsing = false
        }
        
        // Execute action
        action()
    }
}

// MARK: - FAB Style

enum FABStyle {
    case primary        // Główny FAB (niebieski)
    case secondary      // Alternatywny FAB (szary)
    case danger         // FAB dla destructive actions (czerwony)
    case success        // FAB dla positive actions (zielony)
    case compact        // Mniejszy FAB
    case large          // Większy FAB
    case outlined       // FAB z obramowaniem
    case minimal        // Minimalistyczny FAB
    
    var size: CGFloat {
        switch self {
        case .compact:
            return 44
        case .large:
            return 64
        case .primary, .secondary, .danger, .success, .outlined, .minimal:
            return AppTheme.current.layout.fabSize // 56pt
        }
    }
    
    var iconFont: Font {
        switch self {
        case .compact:
            return .title3.weight(.semibold)
        case .large:
            return .title.weight(.bold)
        case .primary, .secondary, .danger, .success, .outlined, .minimal:
            return .title2.weight(.semibold)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return AirLinkColors.primary
        case .secondary:
            return AirLinkColors.buttonSecondary
        case .danger:
            return AirLinkColors.statusError
        case .success:
            return AirLinkColors.statusSuccess
        case .compact, .large:
            return AirLinkColors.primary
        case .outlined:
            return AirLinkColors.background
        case .minimal:
            return AirLinkColors.background.opacity(0.9)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .primary, .danger, .success, .compact, .large:
            return .white
        case .secondary:
            return AirLinkColors.textPrimary
        case .outlined, .minimal:
            return AirLinkColors.primary
        }
    }
    
    var hasGradient: Bool {
        switch self {
        case .primary, .compact, .large:
            return true
        case .secondary, .danger, .success, .outlined, .minimal:
            return false
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .primary, .compact, .large:
            return [AirLinkColors.primary, AirLinkColors.primaryDark]
        default:
            return [backgroundColor, backgroundColor]
        }
    }
    
    var hasBorder: Bool {
        switch self {
        case .outlined:
            return true
        case .primary, .secondary, .danger, .success, .compact, .large, .minimal:
            return false
        }
    }
    
    var borderColor: Color {
        switch self {
        case .outlined:
            return AirLinkColors.primary
        default:
            return Color.clear
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outlined:
            return 2
        default:
            return 0
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary, .compact, .large:
            return AirLinkColors.primary.opacity(0.4)
        case .danger:
            return AirLinkColors.statusError.opacity(0.3)
        case .success:
            return AirLinkColors.statusSuccess.opacity(0.3)
        case .secondary, .outlined, .minimal:
            return AirLinkColors.shadowMedium
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .compact:
            return 6
        case .large:
            return 12
        case .minimal:
            return 4
        case .primary, .secondary, .danger, .success, .outlined:
            return 8
        }
    }
    
    var shadowOffset: CGFloat {
        switch self {
        case .compact, .minimal:
            return 2
        case .large:
            return 6
        case .primary, .secondary, .danger, .success, .outlined:
            return 4
        }
    }
}

// MARK: - Convenience Initializers

extension FloatingActionButton {
    
    /// Standardowy FAB dla głównych akcji
    static func primary(
        icon: String = AppConstants.Icons.add,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> FloatingActionButton {
        FloatingActionButton(
            icon: icon,
            style: .primary,
            isVisible: isVisible,
            action: action
        )
    }
    
    /// FAB dla drugorzędnych akcji
    static func secondary(
        icon: String,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> FloatingActionButton {
        FloatingActionButton(
            icon: icon,
            style: .secondary,
            isVisible: isVisible,
            action: action
        )
    }
    
    /// FAB dla destructive actions
    static func danger(
        icon: String,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> FloatingActionButton {
        FloatingActionButton(
            icon: icon,
            style: .danger,
            isVisible: isVisible,
            hapticFeedback: .heavy,
            action: action
        )
    }
    
    /// Kompaktowy FAB
    static func compact(
        icon: String,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> FloatingActionButton {
        FloatingActionButton(
            icon: icon,
            style: .compact,
            isVisible: isVisible,
            hapticFeedback: .light,
            action: action
        )
    }
    
    /// Duży FAB dla ważnych akcji
    static func large(
        icon: String = AppConstants.Icons.add,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> FloatingActionButton {
        FloatingActionButton(
            icon: icon,
            style: .large,
            isVisible: isVisible,
            hapticFeedback: .heavy,
            action: action
        )
    }
}

// MARK: - FAB Container

/// Container do pozycjonowania FAB na ekranie
struct FABContainer<Content: View>: View {
    
    let content: Content
    let fab: FloatingActionButton
    let position: FABPosition
    let padding: EdgeInsets
    
    init(
        position: FABPosition = .bottomTrailing,
        padding: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 100, trailing: 16),
        @ViewBuilder content: () -> Content,
        @ViewBuilder fab: () -> FloatingActionButton
    ) {
        self.position = position
        self.padding = padding
        self.content = content()
        self.fab = fab()
    }
    
    var body: some View {
        ZStack {
            content
            
            fab
                .padding(padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
        }
    }
}

// MARK: - FAB Position

enum FABPosition {
    case bottomTrailing
    case bottomLeading
    case bottomCenter
    case topTrailing
    case topLeading
    case center
    
    var alignment: Alignment {
        switch self {
        case .bottomTrailing:
            return .bottomTrailing
        case .bottomLeading:
            return .bottomLeading
        case .bottomCenter:
            return .bottom
        case .topTrailing:
            return .topTrailing
        case .topLeading:
            return .topLeading
        case .center:
            return .center
        }
    }
}

// MARK: - View Extensions

extension View {
    
    /// Dodaje FAB do widoku
    func withFAB(
        _ fab: FloatingActionButton,
        position: FABPosition = .bottomTrailing,
        padding: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 100, trailing: 16)
    ) -> some View {
        FABContainer(position: position, padding: padding) {
            self
        } fab: {
            fab
        }
    }
    
    /// Dodaje primary FAB
    func withPrimaryFAB(
        icon: String = AppConstants.Icons.add,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        self.withFAB(
            FloatingActionButton.primary(
                icon: icon,
                isVisible: isVisible,
                action: action
            )
        )
    }
}

// MARK: - Demo & Examples

extension FloatingActionButton {
    
    struct Demo: View {
        
        @State private var isVisible = true
        @State private var selectedStyle: FABStyle = .primary
        @State private var tapCount = 0
        
        var body: some View {
            VStack(spacing: 24) {
                
                Text("FAB Demo")
                    .largeTitleStyle()
                
                // Controls
                VStack(spacing: 16) {
                    Toggle("Visible", isOn: $isVisible)
                    
                    Text("Taps: \(tapCount)")
                        .bodyStyle()
                }
                .defaultCard()
                
                // Different styles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        fabExample(.primary, "Primary")
                        fabExample(.secondary, "Secondary")
                        fabExample(.danger, "Danger")
                        fabExample(.success, "Success")
                        fabExample(.compact, "Compact")
                        fabExample(.large, "Large")
                        fabExample(.outlined, "Outlined")
                        fabExample(.minimal, "Minimal")
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Main demo FAB
                VStack {
                    Text("Główny FAB")
                        .subheadlineStyle()
                    
                    FloatingActionButton(
                        style: selectedStyle,
                        isVisible: isVisible
                    ) {
                        tapCount += 1
                    }
                }
            }
            .padding()
        }
        
        private func fabExample(_ style: FABStyle, _ title: String) -> some View {
            VStack(spacing: 8) {
                FloatingActionButton(
                    style: style,
                    isVisible: isVisible
                ) {
                    selectedStyle = style
                }
                
                Text(title)
                    .caption1Style()
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
    }
}

// MARK: - Preview

#Preview("FAB Styles") {
    VStack(spacing: 20) {
        Text("Floating Action Button Styles")
            .headlineStyle()
        
        // Different styles
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            fabPreview(.primary, "Primary")
            fabPreview(.secondary, "Secondary")
            fabPreview(.danger, "Danger")
            fabPreview(.success, "Success")
            fabPreview(.compact, "Compact")
            fabPreview(.large, "Large")
            fabPreview(.outlined, "Outlined")
            fabPreview(.minimal, "Minimal")
        }
    }
    .padding()
    .background(AirLinkColors.background)
}

private func fabPreview(_ style: FABStyle, _ title: String) -> some View {
    VStack(spacing: 8) {
        FloatingActionButton(style: style) {
            print("Tapped \(title)")
        }
        
        Text(title)
            .caption2Style()
    }
}

#Preview("FAB Demo") {
    FloatingActionButton.Demo()
}

#Preview("FAB in Context") {
    ZStack {
        // Background content
        VStack {
            Text("Home Screen")
                .largeTitleStyle()
            
            Spacer()
            
            Text("Content goes here...")
                .bodyStyle()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AirLinkColors.background)
        
        // FAB
        FloatingActionButton.primary {
            print("New chat tapped")
        }
        .padding(.bottom, 100)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}
