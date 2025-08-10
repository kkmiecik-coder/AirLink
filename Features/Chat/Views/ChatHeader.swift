//
//  ChatHeader.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - ChatHeader

/// Nagłówek czatu z informacjami o uczestnikach i statusie połączenia
/// Obsługuje zarówno rozmowy 1:1 jak i grupowe
struct ChatHeader: View {
    
    // MARK: - Properties
    
    let chat: Chat
    let onlineParticipants: [Contact]
    let connectionStatus: ChatConnectionStatus
    let onParticipantsListTap: () -> Void
    let onBackTap: () -> Void
    
    // MARK: - Environment
    
    @Environment(NavigationCoordinator.self) private var coordinator
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            
            // Back button
            backButton
            
            // Chat info
            chatInfo
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
        .padding(.horizontal, AppTheme.current.spacing.md)
        .padding(.vertical, AppTheme.current.spacing.sm)
        .background(
            Rectangle()
                .fill(AirLinkColors.backgroundSecondary.opacity(0.95))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Back Button
    
    private var backButton: some View {
        Button(action: onBackTap) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AirLinkColors.primary)
        }
    }
    
    // MARK: - Chat Info
    
    private var chatInfo: some View {
        Button(action: onParticipantsListTap) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                
                // Avatar
                chatAvatar
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.displayName)
                        .font(AppTheme.current.typography.headline)
                        .foregroundColor(AirLinkColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(subtitleText)
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(statusColor)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Chat Avatar
    
    @ViewBuilder
    private var chatAvatar: some View {
        if chat.isDirectMessage {
            // Single contact avatar
            if let contact = chat.participants.first {
                AvatarView.contact(contact, size: .medium, showStatus: true)
            } else {
                AvatarView.text("?", size: .medium)
            }
        } else {
            // Group avatar with participants preview
            GroupAvatarView(
                participants: chat.participants,
                onlineCount: onlineParticipants.count,
                size: .medium
            )
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: AppTheme.current.spacing.xs) {
            
            // Signal strength indicator
            if !onlineParticipants.isEmpty {
                signalStrengthIndicator
            }
            
            // More actions menu
            moreActionsMenu
        }
    }
    
    // MARK: - Signal Strength Indicator
    
    private var signalStrengthIndicator: some View {
        VStack(spacing: 2) {
            SignalIndicator.compact(
                strength: averageSignalStrength,
                isMesh: hasMeshConnections
            )
            
            if hasMeshConnections {
                Image(systemName: "network")
                    .font(.caption2)
                    .foregroundColor(AirLinkColors.statusMesh)
            }
        }
    }
    
    // MARK: - More Actions Menu
    
    private var moreActionsMenu: some View {
        Menu {
            if chat.isGroup {
                Button("Uczestnicy") {
                    onParticipantsListTap()
                }
                
                Button("Informacje o grupie") {
                    coordinator.openChatDetails(chat)
                }
                
                Divider()
            } else {
                Button("Informacje o kontakcie") {
                    if let contact = chat.participants.first {
                        coordinator.openContactDetails(contact)
                    }
                }
                
                Divider()
            }
            
            Button(chat.isMuted ? "Wyłącz wyciszenie" : "Wycisz") {
                toggleMute()
            }
            
            Button("Wyczyść historię") {
                clearHistory()
            }
            
            Button("Usuń czat", role: .destructive) {
                deleteChat()
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundColor(AirLinkColors.textSecondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var subtitleText: String {
        if chat.isDirectMessage {
            return singleContactStatus
        } else {
            return groupStatus
        }
    }
    
    private var singleContactStatus: String {
        guard let contact = chat.participants.first else { return "Nieznany" }
        
        if contact.isOnline {
            let signalText = contact.signalStrength > 0 ? " • \(contact.signalStrength)/5" : ""
            let meshText = contact.isConnectedViaMesh ? " • Mesh" : ""
            return "Online\(signalText)\(meshText)"
        } else {
            return contact.lastSeenText
        }
    }
    
    private var groupStatus: String {
        let totalParticipants = chat.participants.count
        let onlineCount = onlineParticipants.count
        
        if onlineCount == 0 {
            return "\(totalParticipants) uczestników • Wszyscy offline"
        } else if onlineCount == totalParticipants {
            return "\(totalParticipants) uczestników • Wszyscy online"
        } else {
            return "\(totalParticipants) uczestników • \(onlineCount) online"
        }
    }
    
    private var statusColor: Color {
        switch connectionStatus {
        case .connected:
            return AirLinkColors.statusSuccess
        case .connecting:
            return AirLinkColors.statusWarning
        case .disconnected:
            return AirLinkColors.statusError
        case .unknown:
            return AirLinkColors.textSecondary
        }
    }
    
    private var averageSignalStrength: Int {
        guard !onlineParticipants.isEmpty else { return 0 }
        
        let totalStrength = onlineParticipants.reduce(0) { $0 + $1.signalStrength }
        return totalStrength / onlineParticipants.count
    }
    
    private var hasMeshConnections: Bool {
        return onlineParticipants.contains { $0.isConnectedViaMesh }
    }
    
    // MARK: - Actions
    
    private func toggleMute() {
        // TODO: Implement mute functionality
        print("Toggle mute for chat: \(chat.displayName)")
    }
    
    private func clearHistory() {
        // TODO: Implement clear history
        print("Clear history for chat: \(chat.displayName)")
    }
    
    private func deleteChat() {
        // TODO: Implement delete chat
        print("Delete chat: \(chat.displayName)")
    }
}

// MARK: - Group Avatar View

private struct GroupAvatarView: View {
    
    let participants: [Contact]
    let onlineCount: Int
    let size: AvatarSize
    
    var body: some View {
        ZStack {
            // Background gradient
            Circle()
                .fill(groupGradient)
                .frame(width: size.dimension, height: size.dimension)
            
            // Group icon
            Image(systemName: "person.2.fill")
                .font(.system(size: size.dimension * 0.35, weight: .medium))
                .foregroundColor(.white)
            
            // Online indicator
            if onlineCount > 0 {
                Circle()
                    .fill(Air
