//
//  Untitled.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - AvatarView Component

/// Reużywalny komponent avatara dla AirLink
/// Obsługuje zarówno zdjęcia użytkowników jak i domyślne avatary z literą
struct AvatarView: View {
    
    // MARK: - Properties
    
    let contact: Contact?
    let size: AvatarSize
    let showOnlineIndicator: Bool
    let showSignalStrength: Bool
    
    // MARK: - Initializers
    
    /// Główny initializer z kontaktem
    init(
        contact: Contact?,
        size: AvatarSize = .medium,
        showOnlineIndicator: Bool = false,
        showSignalStrength: Bool = false
    ) {
        self.contact = contact
        self.size = size
        self.showOnlineIndicator = showOnlineIndicator
        self.showSignalStrength = showSignalStrength
    }
    
    /// Initializer dla avatara bez kontaktu (z tekstem)
    init(
        text: String,
        size: AvatarSize = .medium,
        showOnlineIndicator: Bool = false
    ) {
        // Tworzymy tymczasowy kontakt tylko dla wyświetlenia
        self.contact = Contact(id: "temp", nickname: text)
        self.size = size
        self.showOnlineIndicator = showOnlineIndicator
        self.showSignalStrength = false
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Główny avatar
            mainAvatarView
            
            // Online indicator
            if showOnlineIndicator {
                onlineIndicatorView
            }
            
            // Signal strength indicator
            if showSignalStrength && contact?.isOnline == true {
                signalStrengthView
            }
        }
        .frame(width: size.dimension, height: size.dimension)
    }
    
    // MARK: - Main Avatar View
    
    @ViewBuilder
    private var mainAvatarView: some View {
        if let contact = contact, let avatarData = contact.avatarData,
           let uiImage = UIImage(data: avatarData) {
            // Avatar ze zdjęciem
            photoAvatarView(image: uiImage)
        } else {
            // Domyślny avatar z literą
            letterAvatarView
        }
    }
    
    // MARK: - Photo Avatar
    
    private func photoAvatarView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.dimension, height: size.dimension)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(AirLinkColors.border, lineWidth: 0.5)
            )
    }
    
    // MARK: - Letter Avatar
    
    private var letterAvatarView: some View {
        ZStack {
            // Gradient tło
            Circle()
                .fill(avatarGradient)
            
            // Litera
            Text(avatarLetter)
                .avatarLetterStyle()
                .font(size.letterFont)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
    
    // MARK: - Online Indicator
    
    private var onlineIndicatorView: some View {
        Circle()
            .fill(contact?.isOnline == true ? AirLinkColors.statusOnline : AirLinkColors.statusOffline)
            .frame(width: size.indicatorSize, height: size.indicatorSize)
            .overlay(
                Circle()
                    .stroke(AirLinkColors.background, lineWidth: 2)
            )
            .offset(x: size.indicatorOffset.x, y: size.indicatorOffset.y)
            .animation(AppTheme.current.animations.fast, value: contact?.isOnline)
    }
    
    // MARK: - Signal Strength Indicator
    
    private var signalStrengthView: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                signalBar(for: index)
            }
            
            // Mesh indicator
            if contact?.isConnectedViaMesh == true {
                Image(systemName: AppConstants.Icons.mesh)
                    .font(.system(size: 6, weight: .semibold))
                    .foregroundColor(AirLinkColors.statusMesh)
            }
        }
        .padding(2)
        .background(
            Capsule()
                .fill(AirLinkColors.background.opacity(0.8))
        )
        .offset(x: 0, y: size.signalOffset)
    }
    
    private func signalBar(for index: Int) -> some View {
        Rectangle()
            .fill(signalBarColor(for: index))
            .frame(width: 2, height: signalBarHeight(for: index))
            .animation(AppTheme.current.animations.signalUpdate, value: contact?.signalStrength)
    }
    
    // MARK: - Computed Properties
    
    private var avatarLetter: String {
        contact?.firstLetter ?? "?"
    }
    
    private var avatarGradient: LinearGradient {
        let nickname = contact?.nickname ?? "Unknown"
        return AirLinkColors.avatarGradient(for: nickname)
    }
    
    private func signalBarColor(for index: Int) -> Color {
        let strength = contact?.signalStrength ?? 0
        return index < strength ? AirLinkColors.signalColor(for: strength) : AirLinkColors.signalNone
    }
    
    private func signalBarHeight(for index: Int) -> CGFloat {
        let maxHeight: CGFloat = 8
        return maxHeight * CGFloat(index + 1) / 5.0
    }
}

// MARK: - Avatar Size

enum AvatarSize {
    case small
    case medium
    case large
    case extraLarge
    
    var dimension: CGFloat {
        switch self {
        case .small:
            return AppTheme.current.layout.avatarSmall       // 32pt
        case .medium:
            return AppTheme.current.layout.avatarMedium      // 40pt
        case .large:
            return AppTheme.current.layout.avatarLarge       // 60pt
        case .extraLarge:
            return AppTheme.current.layout.avatarXLarge      // 80pt
        }
    }
    
    var letterFont: Font {
        switch self {
        case .small:
            return .caption.weight(.bold)
        case .medium:
            return .callout.weight(.bold)
        case .large:
            return .title2.weight(.bold)
        case .extraLarge:
            return .title.weight(.bold)
        }
    }
    
    var indicatorSize: CGFloat {
        switch self {
        case .small:
            return 8
        case .medium:
            return 10
        case .large:
            return 14
        case .extraLarge:
            return 18
        }
    }
    
    var indicatorOffset: CGPoint {
        let offset = dimension * 0.35
        return CGPoint(x: offset, y: -offset)
    }
    
    var signalOffset: CGFloat {
        switch self {
        case .small:
            return dimension * 0.25
        case .medium:
            return dimension * 0.25
        case .large:
            return dimension * 0.3
        case .extraLarge:
            return dimension * 0.3
        }
    }
}

// MARK: - Convenience Initializers

extension AvatarView {
    
    /// Avatar z samym tekstem (bez Contact)
    static func text(
        _ text: String,
        size: AvatarSize = .medium
    ) -> AvatarView {
        AvatarView(text: text, size: size)
    }
    
    /// Avatar z kontaktem i wszystkimi wskaźnikami
    static func contact(
        _ contact: Contact,
        size: AvatarSize = .medium,
        showStatus: Bool = true
    ) -> AvatarView {
        AvatarView(
            contact: contact,
            size: size,
            showOnlineIndicator: showStatus,
            showSignalStrength: showStatus
        )
    }
    
    /// Avatar tylko ze zdjęciem/literą (bez statusu)
    static func simple(
        _ contact: Contact?,
        size: AvatarSize = .medium
    ) -> AvatarView {
        AvatarView(
            contact: contact,
            size: size,
            showOnlineIndicator: false,
            showSignalStrength: false
        )
    }
}

// MARK: - Preview

#Preview("Avatar Variants") {
    VStack(spacing: 20) {
        // Różne rozmiary
        HStack(spacing: 16) {
            AvatarView.text("A", size: .small)
            AvatarView.text("B", size: .medium)
            AvatarView.text("C", size: .large)
            AvatarView.text("D", size: .extraLarge)
        }
        
        Divider()
        
        // Z kontaktami
        HStack(spacing: 16) {
            AvatarView.contact(Contact.sampleContact, size: .medium, showStatus: false)
            AvatarView.contact(Contact.sampleOnlineContact, size: .medium, showStatus: true)
            AvatarView.contact(Contact.sampleMeshContact, size: .medium, showStatus: true)
        }
        
        Divider()
        
        // Różne statusy
        HStack(spacing: 16) {
            ForEach(["Anna", "Bartek", "Celina", "Damian"], id: \.self) { name in
                AvatarView.text(name, size: .large)
            }
        }
    }
    .padding()
    .background(AirLinkColors.background)
}

#Preview("Avatar Sizes") {
    HStack(spacing: 20) {
        VStack {
            AvatarView.text("S", size: .small)
            Text("Small")
                .caption2Style()
        }
        
        VStack {
            AvatarView.text("M", size: .medium)
            Text("Medium")
                .caption2Style()
        }
        
        VStack {
            AvatarView.text("L", size: .large)
            Text("Large")
                .caption2Style()
        }
        
        VStack {
            AvatarView.text("XL", size: .extraLarge)
            Text("Extra Large")
                .caption2Style()
        }
    }
    .padding()
    .background(AirLinkColors.background)
}

#Preview("Avatar with Status") {
    let onlineContact = Contact.sampleOnlineContact
    let meshContact = Contact.sampleMeshContact
    
    return VStack(spacing: 20) {
        AvatarView.contact(onlineContact, size: .large, showStatus: true)
        AvatarView.contact(meshContact, size: .large, showStatus: true)
    }
    .padding()
    .background(AirLinkColors.background)
}
