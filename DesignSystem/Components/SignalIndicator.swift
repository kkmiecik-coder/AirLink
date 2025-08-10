//
//  SignalIndicator.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - SignalIndicator Component

/// Komponent wyświetlający siłę sygnału Bluetooth (0-5 kresek)
/// Opcjonalnie z badge'em oznaczającym połączenie mesh
struct SignalIndicator: View {
    
    // MARK: - Properties
    
    let strength: Int  // 0-5 kresek
    let isMesh: Bool   // Czy połączenie przez mesh
    let style: SignalStyle
    let animated: Bool
    
    // MARK: - Initializers
    
    init(
        strength: Int,
        isMesh: Bool = false,
        style: SignalStyle = .standard,
        animated: Bool = true
    ) {
        self.strength = max(0, min(5, strength)) // Clamp 0-5
        self.isMesh = isMesh
        self.style = style
        self.animated = animated
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: style.barSpacing) {
            // Signal bars
            signalBars
            
            // Mesh indicator
            if isMesh {
                meshIndicator
            }
        }
        .padding(style.padding)
        .background(backgroundView)
    }
    
    // MARK: - Signal Bars
    
    private var signalBars: some View {
        HStack(spacing: style.barSpacing) {
            ForEach(0..<5, id: \.self) { index in
                signalBar(for: index)
            }
        }
    }
    
    private func signalBar(for index: Int) -> some View {
        Rectangle()
            .fill(barColor(for: index))
            .frame(
                width: style.barWidth,
                height: barHeight(for: index)
            )
            .cornerRadius(style.barCornerRadius)
            .scaleEffect(
                animated && index < strength ? 1.0 : 0.8,
                anchor: .bottom
            )
            .animation(
                animated ? AppTheme.current.animations.signalUpdate.delay(Double(index) * 0.1) : nil,
                value: strength
            )
    }
    
    // MARK: - Mesh Indicator
    
    private var meshIndicator: some View {
        Image(systemName: AppConstants.Icons.mesh)
            .font(style.meshIconFont)
            .foregroundColor(AirLinkColors.statusMesh)
            .scaleEffect(animated ? 1.0 : 0.9)
            .animation(
                animated ? AppTheme.current.animations.fast : nil,
                value: isMesh
            )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        if style.hasBackground {
            Capsule()
                .fill(style.backgroundColor)
                .shadow(
                    color: style.shadowColor,
                    radius: style.shadowRadius,
                    x: 0,
                    y: style.shadowOffset
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private func barColor(for index: Int) -> Color {
        if index < strength {
            // Aktywna kreska - kolor zależny od siły sygnału
            return AirLinkColors.signalColor(for: strength)
        } else {
            // Nieaktywna kreska
            return AirLinkColors.signalNone
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight = style.maxBarHeight
        let heightMultiplier = CGFloat(index + 1) / 5.0
        return baseHeight * heightMultiplier
    }
}

// MARK: - Signal Style

enum SignalStyle {
    case standard      // Standardowy wygląd
    case compact       // Mniejszy, bardziej kompaktowy
    case large         // Większy, dla głównych elementów UI
    case minimal       // Tylko kreski, bez tła
    case card          // Z tłem jak na karcie
    
    var barWidth: CGFloat {
        switch self {
        case .standard:
            return AppTheme.current.layout.signalBarWidth    // 3pt
        case .compact:
            return 2
        case .large:
            return 4
        case .minimal:
            return 2.5
        case .card:
            return 3
        }
    }
    
    var maxBarHeight: CGFloat {
        switch self {
        case .standard:
            return AppTheme.current.layout.signalBarMaxHeight // 12pt
        case .compact:
            return 8
        case .large:
            return 16
        case .minimal:
            return 10
        case .card:
            return 14
        }
    }
    
    var barSpacing: CGFloat {
        switch self {
        case .standard:
            return AppTheme.current.layout.signalBarSpacing  // 2pt
        case .compact:
            return 1
        case .large:
            return 3
        case .minimal:
            return 1.5
        case .card:
            return 2
        }
    }
    
    var barCornerRadius: CGFloat {
        switch self {
        case .standard, .compact, .minimal:
            return 0.5
        case .large:
            return 1
        case .card:
            return 1
        }
    }
    
    var meshIconFont: Font {
        switch self {
        case .standard, .card:
            return .caption2.weight(.semibold)
        case .compact:
            return .system(size: 8, weight: .semibold)
        case .large:
            return .footnote.weight(.semibold)
        case .minimal:
            return .system(size: 10, weight: .semibold)
        }
    }
    
    var hasBackground: Bool {
        switch self {
        case .standard, .large, .card:
            return true
        case .compact, .minimal:
            return false
        }
    }
    
    var backgroundColor: Color {
        return AirLinkColors.background.opacity(0.9)
    }
    
    var shadowColor: Color {
        return AirLinkColors.shadowLight
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .standard, .compact, .minimal:
            return 1
        case .large:
            return 2
        case .card:
            return 3
        }
    }
    
    var shadowOffset: CGFloat {
        switch self {
        case .standard, .compact, .minimal:
            return 0.5
        case .large:
            return 1
        case .card:
            return 1.5
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .standard:
            return EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
        case .compact:
            return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
        case .large:
            return EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        case .minimal:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        case .card:
            return EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        }
    }
}

// MARK: - Convenience Initializers

extension SignalIndicator {
    
    /// Standardowy wskaźnik sygnału
    static func standard(strength: Int, isMesh: Bool = false) -> SignalIndicator {
        SignalIndicator(strength: strength, isMesh: isMesh, style: .standard)
    }
    
    /// Kompaktowy wskaźnik (np. w liście kontaktów)
    static func compact(strength: Int, isMesh: Bool = false) -> SignalIndicator {
        SignalIndicator(strength: strength, isMesh: isMesh, style: .compact)
    }
    
    /// Duży wskaźnik (np. w nagłówku czatu)
    static func large(strength: Int, isMesh: Bool = false) -> SignalIndicator {
        SignalIndicator(strength: strength, isMesh: isMesh, style: .large)
    }
    
    /// Minimalny wskaźnik (tylko kreski)
    static func minimal(strength: Int, isMesh: Bool = false) -> SignalIndicator {
        SignalIndicator(strength: strength, isMesh: isMesh, style: .minimal, animated: false)
    }
    
    /// Wskaźnik na karcie
    static func card(strength: Int, isMesh: Bool = false) -> SignalIndicator {
        SignalIndicator(strength: strength, isMesh: isMesh, style: .card)
    }
}

// MARK: - Demo States

extension SignalIndicator {
    
    /// Demo różnych stanów sygnału
    struct Demo: View {
        
        @State private var currentStrength = 0
        @State private var isMesh = false
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Signal Strength Demo")
                    .headlineStyle()
                
                // Live demo z kontrolkami
                VStack(spacing: 16) {
                    SignalIndicator.large(strength: currentStrength, isMesh: isMesh)
                    
                    HStack {
                        Text("Siła sygnału: \(currentStrength)")
                        Stepper("", value: $currentStrength, in: 0...5)
                    }
                    
                    Toggle("Mesh Network", isOn: $isMesh)
                }
                .defaultCard()
                
                Divider()
                
                // Wszystkie style
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wszystkie style")
                        .subheadlineStyle()
                    
                    HStack {
                        Text("Standard:")
                        Spacer()
                        SignalIndicator.standard(strength: 4, isMesh: true)
                    }
                    
                    HStack {
                        Text("Compact:")
                        Spacer()
                        SignalIndicator.compact(strength: 3)
                    }
                    
                    HStack {
                        Text("Large:")
                        Spacer()
                        SignalIndicator.large(strength: 5, isMesh: true)
                    }
                    
                    HStack {
                        Text("Minimal:")
                        Spacer()
                        SignalIndicator.minimal(strength: 2)
                    }
                    
                    HStack {
                        Text("Card:")
                        Spacer()
                        SignalIndicator.card(strength: 1, isMesh: true)
                    }
                }
                .defaultCard()
            }
            .padding()
            .onAppear {
                startDemo()
            }
        }
        
        private func startDemo() {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                withAnimation {
                    currentStrength = Int.random(in: 0...5)
                    if Bool.random() {
                        isMesh.toggle()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Signal Indicator") {
    VStack(spacing: 20) {
        // Różne poziomy sygnału
        HStack(spacing: 16) {
            ForEach(0...5, id: \.self) { strength in
                VStack {
                    SignalIndicator.standard(strength: strength)
                    Text("\(strength)")
                        .caption2Style()
                }
            }
        }
        
        Divider()
        
        // Z mesh network
        HStack(spacing: 16) {
            SignalIndicator.standard(strength: 3, isMesh: false)
            SignalIndicator.standard(strength: 3, isMesh: true)
        }
        
        Divider()
        
        // Różne style
        VStack(spacing: 12) {
            SignalIndicator.standard(strength: 4, isMesh: true)
            SignalIndicator.compact(strength: 4, isMesh: true)
            SignalIndicator.large(strength: 4, isMesh: true)
            SignalIndicator.minimal(strength: 4, isMesh: true)
            SignalIndicator.card(strength: 4, isMesh: true)
        }
    }
    .padding()
    .background(AirLinkColors.background)
}

#Preview("Signal Demo") {
    SignalIndicator.Demo()
}
