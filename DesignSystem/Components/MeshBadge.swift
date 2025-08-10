//
//  MeshBadge.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - MeshBadge Component

/// Mały badge oznaczający połączenie przez mesh network
/// Może być używany jako overlay na avatarach, wiadomościach, itp.
struct MeshBadge: View {
    
    // MARK: - Properties
    
    let style: MeshBadgeStyle
    let hops: Int?         // Liczba "skoków" przez mesh (opcjonalne)
    let animated: Bool
    
    // MARK: - Initializers
    
    init(
        style: MeshBadgeStyle = .standard,
        hops: Int? = nil,
        animated: Bool = true
    ) {
        self.style = style
        self.hops = hops
        self.animated = animated
    }
    
    // MARK: - Body
    
    var body: some View {
        badgeContent
            .padding(style.padding)
            .background(backgroundView)
            .scaleEffect(animated ? 1.0 : 0.9)
            .opacity(animated ? 1.0 : 0.8)
            .animation(
                animated ? AppTheme.current.animations.fast : nil,
                value: animated
            )
    }
    
    // MARK: - Badge Content
    
    @ViewBuilder
    private var badgeContent: some View {
        switch style {
        case .icon:
            iconOnlyView
        case .iconWithHops:
            iconWithHopsView
        case .text:
            textOnlyView
        case .pill:
            pillView
        case .minimal:
            minimalView
        }
    }
    
    // MARK: - Icon Only
    
    private var iconOnlyView: some View {
        Image(systemName: AppConstants.Icons.mesh)
            .font(style.iconFont)
            .foregroundColor(style.iconColor)
    }
    
    // MARK: - Icon with Hops
    
    private var iconWithHopsView: some View {
        HStack(spacing: 2) {
            Image(systemName: AppConstants.Icons.mesh)
                .font(style.iconFont)
                .foregroundColor(style.iconColor)
            
            if let hops = hops, hops > 0 {
                Text("\(hops)")
                    .font(style.textFont)
                    .foregroundColor(style.textColor)
            }
        }
    }
    
    // MARK: - Text Only
    
    private var textOnlyView: some View {
        Group {
            if let hops = hops, hops > 0 {
                Text("Mesh (\(hops))")
            } else {
                Text("Mesh")
            }
        }
        .font(style.textFont)
        .foregroundColor(style.textColor)
    }
    
    // MARK: - Pill Style
    
    private var pillView: some View {
        HStack(spacing: 4) {
            Image(systemName: AppConstants.Icons.mesh)
                .font(style.iconFont)
                .foregroundColor(style.iconColor)
            
            Group {
                if let hops = hops, hops > 0 {
                    Text("Mesh (\(hops))")
                } else {
                    Text("Mesh")
                }
            }
            .font(style.textFont)
            .foregroundColor(style.textColor)
        }
    }
    
    // MARK: - Minimal Style
    
    private var minimalView: some View {
        Circle()
            .fill(AirLinkColors.statusMesh)
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .stroke(AirLinkColors.background, lineWidth: 1)
            )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        if style.hasBackground {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                )
                .shadow(
                    color: style.shadowColor,
                    radius: style.shadowRadius,
                    x: 0,
                    y: style.shadowOffset
                )
        }
    }
}

// MARK: - MeshBadge Style

enum MeshBadgeStyle {
    case icon           // Tylko ikona
    case iconWithHops   // Ikona + liczba skoków
    case text           // Tylko tekst "Mesh" lub "Mesh (2)"
    case pill           // Pełny pill z ikoną i tekstem
    case minimal        // Mała kropka
    
    var iconFont: Font {
        switch self {
        case .icon:
            return .caption.weight(.semibold)
        case .iconWithHops:
            return .caption2.weight(.semibold)
        case .text:
            return .caption2.weight(.medium) // Nie używane
        case .pill:
            return .caption2.weight(.semibold)
        case .minimal:
            return .caption2.weight(.semibold) // Nie używane
        }
    }
    
    var textFont: Font {
        switch self {
        case .icon, .minimal:
            return .caption2.weight(.medium) // Nie używane
        case .iconWithHops:
            return .caption2.weight(.medium)
        case .text:
            return .caption2.weight(.medium)
        case .pill:
            return .caption2.weight(.medium)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .icon, .iconWithHops:
            return AirLinkColors.statusMesh
        case .text, .minimal:
            return AirLinkColors.statusMesh // Nie używane
        case .pill:
            return AirLinkColors.statusMesh
        }
    }
    
    var textColor: Color {
        switch self {
        case .icon, .minimal:
            return AirLinkColors.textSecondary // Nie używane
        case .iconWithHops, .text:
            return AirLinkColors.statusMesh
        case .pill:
            return AirLinkColors.statusMesh
        }
    }
    
    var hasBackground: Bool {
        switch self {
        case .icon, .iconWithHops, .text, .minimal:
            return false
        case .pill:
            return true
        }
    }
    
    var backgroundColor: Color {
        return AirLinkColors.background.opacity(0.95)
    }
    
    var borderColor: Color {
        return AirLinkColors.statusMesh.opacity(0.3)
    }
    
    var borderWidth: CGFloat {
        return 0.5
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .pill:
            return 12
        default:
            return 6
        }
    }
    
    var shadowColor: Color {
        return AirLinkColors.shadowLight
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .pill:
            return 2
        default:
            return 1
        }
    }
    
    var shadowOffset: CGFloat {
        return 1
    }
    
    var padding: EdgeInsets {
        switch self {
        case .icon:
            return EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        case .iconWithHops:
            return EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3)
        case .text:
            return EdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 2)
        case .pill:
            return EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
        case .minimal:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
    }
}

// MARK: - Convenience Initializers

extension MeshBadge {
    
    /// Standardowy badge z ikoną
    static func icon(animated: Bool = true) -> MeshBadge {
        MeshBadge(style: .icon, animated: animated)
    }
    
    /// Badge z ikoną i liczbą skoków
    static func iconWithHops(_ hops: Int, animated: Bool = true) -> MeshBadge {
        MeshBadge(style: .iconWithHops, hops: hops, animated: animated)
    }
    
    /// Badge z tekstem
    static func text(hops: Int? = nil, animated: Bool = true) -> MeshBadge {
        MeshBadge(style: .text, hops: hops, animated: animated)
    }
    
    /// Pełny pill badge
    static func pill(hops: Int? = nil, animated: Bool = true) -> MeshBadge {
        MeshBadge(style: .pill, hops: hops, animated: animated)
    }
    
    /// Minimalny badge (kropka)
    static func minimal(animated: Bool = true) -> MeshBadge {
        MeshBadge(style: .minimal, animated: animated)
    }
}

// MARK: - View Extensions

extension View {
    
    /// Dodaje mesh badge jako overlay
    func meshBadge(
        _ style: MeshBadgeStyle = .icon,
        hops: Int? = nil,
        alignment: Alignment = .topTrailing,
        offset: CGPoint = CGPoint(x: -4, y: 4)
    ) -> some View {
        self.overlay(
            MeshBadge(style: style, hops: hops)
                .offset(x: offset.x, y: offset.y),
            alignment: alignment
        )
    }
    
    /// Dodaje minimalny mesh indicator
    func meshIndicator(
        isVisible: Bool = true,
        alignment: Alignment = .topTrailing
    ) -> some View {
        self.overlay(
            Group {
                if isVisible {
                    MeshBadge.minimal()
                }
            },
            alignment: alignment
        )
    }
}

// MARK: - Usage Examples

extension MeshBadge {
    
    /// Przykłady użycia w różnych kontekstach
    struct Examples: View {
        
        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Różne style
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Style badge'ów")
                            .headlineStyle()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Icon:")
                                Spacer()
                                MeshBadge.icon()
                            }
                            
                            HStack {
                                Text("Icon + Hops:")
                                Spacer()
                                MeshBadge.iconWithHops(3)
                            }
                            
                            HStack {
                                Text("Text:")
                                Spacer()
                                MeshBadge.text(hops: 2)
                            }
                            
                            HStack {
                                Text("Pill:")
                                Spacer()
                                MeshBadge.pill(hops: 1)
                            }
                            
                            HStack {
                                Text("Minimal:")
                                Spacer()
                                MeshBadge.minimal()
                            }
                        }
                    }
                    .defaultCard()
                    
                    // Na elementach UI
                    VStack(alignment: .leading, spacing: 12) {
                        Text("W kontekście UI")
                            .headlineStyle()
                        
                        HStack(spacing: 16) {
                            // Na kole (jak avatar)
                            Circle()
                                .fill(AirLinkColors.primary)
                                .frame(width: 40, height: 40)
                                .meshBadge(.minimal)
                            
                            // Na karcie
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AirLinkColors.backgroundCard)
                                .frame(width: 60, height: 40)
                                .meshBadge(.iconWithHops, hops: 2)
                            
                            // Na message bubble
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AirLinkColors.myMessageBackground)
                                .frame(width: 80, height: 30)
                                .meshBadge(.icon, alignment: .bottomTrailing, offset: CGPoint(x: -2, y: -2))
                        }
                    }
                    .defaultCard()
                    
                    // Różne liczby skoków
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Różna liczba skoków")
                            .headlineStyle()
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { hops in
                                MeshBadge.pill(hops: hops)
                            }
                        }
                    }
                    .defaultCard()
                }
                .padding()
            }
        }
    }
}

// MARK: - Preview

#Preview("Mesh Badge Styles") {
    VStack(spacing: 20) {
        // Wszystkie style
        HStack(spacing: 16) {
            MeshBadge.icon()
            MeshBadge.iconWithHops(2)
            MeshBadge.text(hops: 3)
            MeshBadge.pill(hops: 1)
            MeshBadge.minimal()
        }
        
        Divider()
        
        // Na różnych elementach
        HStack(spacing: 20) {
            // Avatar z badge
            Circle()
                .fill(AirLinkColors.primary)
                .frame(width: 50, height: 50)
                .meshBadge(.minimal)
            
            // Message z badge
            RoundedRectangle(cornerRadius: 16)
                .fill(AirLinkColors.myMessageBackground)
                .frame(width: 100, height: 40)
                .meshBadge(.icon, alignment: .bottomTrailing)
            
            // Card z badge
            RoundedRectangle(cornerRadius: 12)
                .fill(AirLinkColors.backgroundCard)
                .frame(width: 80, height: 60)
                .meshBadge(.iconWithHops, hops: 3)
        }
    }
    .padding()
    .background(AirLinkColors.background)
}

#Preview("Mesh Badge Examples") {
    MeshBadge.Examples()
}
