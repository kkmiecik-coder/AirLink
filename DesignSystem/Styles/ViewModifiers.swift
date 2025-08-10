//
//  ViewModifiers.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - AirLink View Modifiers

/// Kolekcja reużywalnych modyfikatorów widoków dla AirLink
/// Zapewnia spójny wygląd i zachowanie w całej aplikacji

// MARK: - Card Modifiers

struct CardModifier: ViewModifier {
    
    let style: CardStyle
    let padding: CGFloat
    
    init(style: CardStyle = .default, padding: CGFloat = AppTheme.current.spacing.cardPadding) {
        self.style = style
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AirLinkColors.backgroundCard)
            .cornerRadius(AppTheme.current.layout.cornerRadiusMedium)
            .conditionalModifier(style == .elevated) { view in
                view.shadow(
                    color: AppTheme.current.shadows.elevation2.color,
                    radius: AppTheme.current.shadows.elevation2.radius,
                    x: AppTheme.current.shadows.elevation2.x,
                    y: AppTheme.current.shadows.elevation2.y
                )
            }
    }
    
    enum CardStyle {
        case `default`
        case elevated
    }
}

// MARK: - Message Bubble Modifier

struct MessageBubbleModifier: ViewModifier {
    
    let isFromCurrentUser: Bool
    let maxWidth: CGFloat
    
    init(isFromCurrentUser: Bool, maxWidth: CGFloat = AppTheme.current.layout.maxMessageWidth) {
        self.isFromCurrentUser = isFromCurrentUser
        self.maxWidth = maxWidth
    }
    
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.current.spacing.messageBubblePadding)
            .background(backgroundColor)
            .cornerRadius(AppTheme.current.layout.messageBubbleRadius)
            .frame(maxWidth: maxWidth, alignment: alignment)
            .shadow(
                color: AppTheme.current.shadows.messageBubbleShadow.color,
                radius: AppTheme.current.shadows.messageBubbleShadow.radius,
                x: AppTheme.current.shadows.messageBubbleShadow.x,
                y: AppTheme.current.shadows.messageBubbleShadow.y
            )
    }
    
    private var backgroundColor: Color {
        isFromCurrentUser ? AirLinkColors.myMessageBackground : AirLinkColors.otherMessageBackground
    }
    
    private var alignment: Alignment {
        isFromCurrentUser ? .trailing : .leading
    }
}

// MARK: - Loading Modifier

struct LoadingModifier: ViewModifier {
    
    let isLoading: Bool
    let style: LoadingStyle
    
    init(isLoading: Bool, style: LoadingStyle = .overlay) {
        self.isLoading = isLoading
        self.style = style
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading && style == .overlay ? 2 : 0)
            
            if isLoading {
                switch style {
                case .overlay:
                    overlayLoadingView
                case .inline:
                    inlineLoadingView
                case .replace:
                    replaceLoadingView
                }
            }
        }
        .animation(AppTheme.current.animations.medium, value: isLoading)
    }
    
    private var overlayLoadingView: some View {
        Rectangle()
            .fill(AirLinkColors.overlayLight)
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AirLinkColors.primary))
                    .scaleEffect(1.2)
            )
    }
    
    private var inlineLoadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AirLinkColors.primary))
            Spacer()
        }
        .padding()
    }
    
    private var replaceLoadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: AirLinkColors.primary))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AirLinkColors.background)
    }
    
    enum LoadingStyle {
        case overlay
        case inline
        case replace
    }
}

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                AirLinkColors.backgroundSecondary.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(70))
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Haptic Feedback Modifier

struct HapticFeedbackModifier: ViewModifier {
    
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _ in
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
    }
}

// MARK: - Keyboard Responsive Modifier

struct KeyboardResponsiveModifier: ViewModifier {
    
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .animation(AppTheme.current.animations.medium, value: keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
    }
}

// MARK: - Badge Modifier

struct BadgeModifier: ViewModifier {
    
    let count: Int
    let color: Color
    let offset: CGPoint
    
    init(count: Int, color: Color = AirLinkColors.statusError, offset: CGPoint = CGPoint(x: 8, y: -8)) {
        self.count = count
        self.color = color
        self.offset = offset
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if count > 0 {
                        badgeView
                            .offset(x: offset.x, y: offset.y)
                    }
                },
                alignment: .topTrailing
            )
    }
    
    private var badgeView: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, count > 9 ? 6 : 0)
            .frame(minWidth: 20, minHeight: 20)
            .background(color)
            .clipShape(Circle())
    }
}

// MARK: - Signal Strength Modifier

struct SignalStrengthModifier: ViewModifier {
    
    let strength: Int
    let isMesh: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                HStack(spacing: AppTheme.current.layout.signalBarSpacing) {
                    ForEach(0..<5, id: \.self) { index in
                        signalBar(for: index)
                    }
                    
                    if isMesh {
                        Image(systemName: AppConstants.Icons.mesh)
                            .font(.caption2)
                            .foregroundColor(AirLinkColors.statusMesh)
                    }
                }
                .padding(4),
                alignment: .topTrailing
            )
    }
    
    private func signalBar(for index: Int) -> some View {
        Rectangle()
            .fill(signalBarColor(for: index))
            .frame(
                width: AppTheme.current.layout.signalBarWidth,
                height: signalBarHeight(for: index)
            )
            .animation(AppTheme.current.animations.signalUpdate, value: strength)
    }
    
    private func signalBarColor(for index: Int) -> Color {
        return index < strength ? AirLinkColors.signalColor(for: strength) : AirLinkColors.signalNone
    }
    
    private func signalBarHeight(for index: Int) -> CGFloat {
        let maxHeight = AppTheme.current.layout.signalBarMaxHeight
        return maxHeight * CGFloat(index + 1) / 5.0
    }
}

// MARK: - Error State Modifier

struct ErrorStateModifier: ViewModifier {
    
    let error: Error?
    let retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        Group {
            if let error = error {
                VStack(spacing: AppTheme.current.spacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(AirLinkColors.statusError)
                    
                    Text("Wystąpił błąd")
                        .headlineStyle()
                    
                    Text(error.localizedDescription)
                        .footnoteStyle()
                        .multilineTextAlignment(.center)
                    
                    if let retryAction = retryAction {
                        Button("Spróbuj ponownie", action: retryAction)
                            .primaryStyle()
                    }
                }
                .padding(AppTheme.current.spacing.xl)
            } else {
                content
            }
        }
    }
}

// MARK: - Conditional Modifier

extension View {
    
    /// Stosuje modyfikator warunkowo
    @ViewBuilder
    func conditionalModifier<T: View>(
        _ condition: Bool,
        transform: (Self) -> T
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Stosuje modyfikator jeśli wartość nie jest nil
    @ViewBuilder
    func conditionalModifier<T: View, U>(
        _ value: U?,
        transform: (Self, U) -> T
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - View Extensions for Modifiers

extension View {
    
    // MARK: - Card Modifiers
    
    func defaultCard(padding: CGFloat = AppTheme.current.spacing.cardPadding) -> some View {
        self.modifier(CardModifier(style: .default, padding: padding))
    }
    
    func elevatedCard(padding: CGFloat = AppTheme.current.spacing.cardPadding) -> some View {
        self.modifier(CardModifier(style: .elevated, padding: padding))
    }
    
    // MARK: - Message Bubble
    
    func messageBubble(isFromCurrentUser: Bool, maxWidth: CGFloat = AppTheme.current.layout.maxMessageWidth) -> some View {
        self.modifier(MessageBubbleModifier(isFromCurrentUser: isFromCurrentUser, maxWidth: maxWidth))
    }
    
    // MARK: - Loading States
    
    func loading(_ isLoading: Bool, style: LoadingModifier.LoadingStyle = .overlay) -> some View {
        self.modifier(LoadingModifier(isLoading: isLoading, style: style))
    }
    
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    // MARK: - Interactive Feedback
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle, trigger: Bool) -> some View {
        self.modifier(HapticFeedbackModifier(style: style, trigger: trigger))
    }
    
    // MARK: - Keyboard Handling
    
    func keyboardResponsive() -> some View {
        self.modifier(KeyboardResponsiveModifier())
    }
    
    // MARK: - Badge
    
    func badge(_ count: Int, color: Color = AirLinkColors.statusError, offset: CGPoint = CGPoint(x: 8, y: -8)) -> some View {
        self.modifier(BadgeModifier(count: count, color: color, offset: offset))
    }
    
    // MARK: - Signal Strength
    
    func signalStrength(_ strength: Int, isMesh: Bool = false) -> some View {
        self.modifier(SignalStrengthModifier(strength: strength, isMesh: isMesh))
    }
    
    // MARK: - Error Handling
    
    func errorState(_ error: Error?, retryAction: (() -> Void)? = nil) -> some View {
        self.modifier(ErrorStateModifier(error: error, retryAction: retryAction))
    }
    
    // MARK: - Quick Styling
    
    func airLinkShadow(_ level: Int = 1) -> some View {
        let shadow = level == 1 ? AppTheme.current.shadows.elevation1 :
                    level == 2 ? AppTheme.current.shadows.elevation2 :
                    AppTheme.current.shadows.elevation3
        
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    func airLinkCornerRadius(_ size: CornerRadiusSize = .medium) -> some View {
        let radius: CGFloat = switch size {
        case .small: AppTheme.current.layout.cornerRadiusSmall
        case .medium: AppTheme.current.layout.cornerRadiusMedium
        case .large: AppTheme.current.layout.cornerRadiusLarge
        case .extraLarge: AppTheme.current.layout.cornerRadiusXLarge
        }
        
        return self.cornerRadius(radius)
    }
    
    func airLinkPadding(_ size: PaddingSize = .medium) -> some View {
        let padding: CGFloat = switch size {
        case .extraSmall: AppTheme.current.spacing.xs
        case .small: AppTheme.current.spacing.sm
        case .medium: AppTheme.current.spacing.md
        case .large: AppTheme.current.spacing.lg
        case .extraLarge: AppTheme.current.spacing.xl
        case .extraExtraLarge: AppTheme.current.spacing.xxl
        }
        
        return self.padding(padding)
    }
}

// MARK: - Helper Enums

enum CornerRadiusSize {
    case small, medium, large, extraLarge
}

enum PaddingSize {
    case extraSmall, small, medium, large, extraLarge, extraExtraLarge
}
