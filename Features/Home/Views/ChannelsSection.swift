//
//  ChannelsSection.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - ChannelsSection

/// Sekcja kanałów grupowych na ekranie głównym
/// Wyświetla listę grup/kanałów z podstawowymi informacjami
struct ChannelsSection: View {
    
    // MARK: - Environment
    
    @Environment(ChatService.self) private var chatService
    @Environment(NavigationCoordinator.self) private var coordinator
    
    // MARK: - Properties
    
    let channels: [Chat]
    let isLoading: Bool
    
    // MARK: - State
    
    @State private var showingCreateGroup = false
    
    // MARK: - Body
    
    var body: some View {
        Section {
            if isLoading {
                loadingView
            } else if channels.isEmpty {
                emptyChannelsView
            } else {
                channelsList
            }
        } header: {
            sectionHeader
        }
    }
    
    // MARK: - Section Header
    
    private var sectionHeader: some View {
        HStack {
            Text("Kanały")
                .sectionHeaderStyle()
            
            Spacer()
            
            if !channels.isEmpty {
                Button("Nowy") {
                    showingCreateGroup = true
                }
                .font(AppTheme.current.typography.buttonSmall)
                .foregroundColor(AirLinkColors.primary)
            }
        }
        .padding(.horizontal, AppTheme.current.spacing.md)
    }
    
    // MARK: - Channels List
    
    private var channelsList: some View {
        LazyVStack(spacing: AppTheme.current.spacing.xs) {
            ForEach(channels) { channel in
                ChannelRow(
                    channel: channel,
                    onTap: { openChannel(channel) },
                    onDelete: { deleteChannel(channel) }
                )
                .contextMenu {
                    channelContextMenu(for: channel)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyChannelsView: some View {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "Brak kanałów",
            description: "Utwórz grupę żeby rozpocząć rozmowy z wieloma osobami",
            actionTitle: "Utwórz grupę",
            actionIcon: "plus.circle",
            style: .compact
        ) {
            showingCreateGroup = true
        }
        .padding(.vertical, AppTheme.current.spacing.md)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.current.spacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                ChannelRowSkeleton()
            }
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func channelContextMenu(for channel: Chat) -> some View {
        Button("Otwórz") {
            openChannel(channel)
        }
        
        Button("Informacje") {
            coordinator.openChatDetails(channel)
        }
        
        if channel.isMuted {
            Button("Wyłącz wyciszenie") {
                toggleMute(channel)
            }
        } else {
            Button("Wycisz") {
                toggleMute(channel)
            }
        }
        
        Divider()
        
        Button("Usuń", role: .destructive) {
            deleteChannel(channel)
        }
    }
    
    // MARK: - Actions
    
    private func openChannel(_ channel: Chat) {
        coordinator.openChat(channel)
    }
    
    private func deleteChannel(_ channel: Chat) {
        Task {
            try await chatService.deleteChat(channel)
        }
    }
    
    private func toggleMute(_ channel: Chat) {
        Task {
            try await chatService.toggleMute(for: channel)
        }
    }
}

// MARK: - Channel Row

private struct ChannelRow: View {
    
    let channel: Chat
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                // Group Avatar
                groupAvatar
                
                // Channel Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(channel.displayName)
                            .chatTitleStyle()
                        
                        Spacer()
                        
                        if let lastMessageDate = channel.lastMessageDate {
                            Text(formatTime(lastMessageDate))
                                .chatTimeStyle()
                        }
                    }
                    
                    HStack {
                        Text(lastMessagePreview)
                            .chatPreviewStyle()
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Badges
                        badgesView
                    }
                }
            }
            .padding(.horizontal, AppTheme.current.spacing.md)
            .padding(.vertical, AppTheme.current.spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Usuń", role: .destructive) {
                onDelete()
            }
        }
    }
    
    // MARK: - Group Avatar
    
    private var groupAvatar: some View {
        ZStack {
            Circle()
                .fill(AirLinkColors.avatarGradient(for: channel.displayName))
                .frame(width: 44, height: 44)
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Last Message Preview
    
    private var lastMessagePreview: String {
        if let preview = channel.lastMessagePreview, !preview.isEmpty {
            return preview
        }
        return "Brak wiadomości"
    }
    
    // MARK: - Badges View
    
    @ViewBuilder
    private var badgesView: some View {
        HStack(spacing: 4) {
            // Unread count
            if channel.unreadCount > 0 {
                Text("\(channel.unreadCount)")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(AirLinkColors.statusError)
                    )
            }
            
            // Muted indicator
            if channel.isMuted {
                Image(systemName: "speaker.slash.fill")
                    .font(.caption2)
                    .foregroundColor(AirLinkColors.textTertiary)
            }
            
            // Active indicator
            if channel.isActive {
                Circle()
                    .fill(AirLinkColors.statusSuccess)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
        } else if Calendar.current.isDateInYesterday(date) {
            return "wczoraj"
        } else {
            formatter.dateStyle = .short
        }
        return formatter.string(from: date)
    }
}

// MARK: - Channel Row Skeleton

private struct ChannelRowSkeleton: View {
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            // Avatar skeleton
            Circle()
                .fill(AirLinkColors.backgroundTertiary)
                .frame(width: 44, height: 44)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 4) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(AirLinkColors.backgroundTertiary)
                    .frame(height: 16)
                    .frame(width: .random(in: 80...140))
                    .shimmer()
                
                // Preview skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(AirLinkColors.backgroundTertiary)
                    .frame(height: 14)
                    .frame(width: .random(in: 120...200))
                    .shimmer()
            }
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.current.spacing.md)
        .padding(.vertical, AppTheme.current.spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        List {
            ChannelsSection(
                channels: Chat.sampleGroupChats,
                isLoading: false
            )
        }
        .listStyle(PlainListStyle())
    }
    .withAppTheme()
}

#Preview("Loading") {
    NavigationView {
        List {
            ChannelsSection(
                channels: [],
                isLoading: true
            )
        }
        .listStyle(PlainListStyle())
    }
    .withAppTheme()
}

#Preview("Empty") {
    NavigationView {
        List {
            ChannelsSection(
                channels: [],
                isLoading: false
            )
        }
        .listStyle(PlainListStyle())
    }
    .withAppTheme()
}
