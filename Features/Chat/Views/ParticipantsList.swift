//
//  ParticipantsList.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

//
//  ParticipantsList.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - ParticipantsList

/// Lista uczestników czatu grupowego
/// Wyświetla informacje o uczestnikach, ich statusie online i opcjach zarządzania
struct ParticipantsList: View {
    
    // MARK: - Properties
    
    let chat: Chat
    let participants: [Contact]
    let onlineParticipants: [Contact]
    let onDismiss: () -> Void
    
    // MARK: - Environment
    
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(ContactService.self) private var contactService
    @Environment(ChatService.self) private var chatService
    
    // MARK: - State
    
    @State private var showingAddParticipants = false
    @State private var showingRemoveConfirmation = false
    @State private var participantToRemove: Contact?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Chat info section
                chatInfoSection
                
                // Participants section
                participantsSection
                
                // Add participants section
                if chat.isGroup {
                    addParticipantsSection
                }
                
                // Chat actions section
                chatActionsSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Uczestnicy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gotowe") {
                        onDismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddParticipants) {
            AddParticipantsSheet(
                chat: chat,
                existingParticipants: participants,
                onDismiss: { showingAddParticipants = false }
            )
        }
        .confirmationDialog(
            "Usuń uczestnika",
            isPresented: $showingRemoveConfirmation,
            presenting: participantToRemove
        ) { participant in
            Button("Usuń \(participant.nickname)", role: .destructive) {
                removeParticipant(participant)
            }
            Button("Anuluj", role: .cancel) {}
        } message: { participant in
            Text("Czy na pewno chcesz usunąć \(participant.nickname) z grupy?")
        }
    }
    
    // MARK: - Chat Info Section
    
    private var chatInfoSection: some View {
        Section {
            HStack(spacing: AppTheme.current.spacing.md) {
                // Group avatar
                GroupAvatarView(
                    participants: participants,
                    onlineCount: onlineParticipants.count,
                    size: .large
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.displayName)
                        .font(AppTheme.current.typography.title3)
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    Text(groupStatusText)
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(AirLinkColors.textSecondary)
                    
                    if !onlineParticipants.isEmpty {
                        HStack(spacing: 4) {
                            SignalIndicator.compact(
                                strength: averageSignalStrength,
                                isMesh: hasMeshConnections
                            )
                            
                            Text("Średni sygnał: \(averageSignalStrength)/5")
                                .font(.caption2)
                                .foregroundColor(AirLinkColors.textTertiary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, AppTheme.current.spacing.sm)
        }
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        Section("Uczestnicy (\(participants.count))") {
            ForEach(participants) { participant in
                ParticipantRow(
                    participant: participant,
                    isOnline: onlineParticipants.contains(participant),
                    isCurrentUser: participant.isCurrentUser,
                    canRemove: chat.isGroup && !participant.isCurrentUser,
                    onTap: { openParticipantDetails(participant) },
                    onRemove: { showRemoveConfirmation(for: participant) }
                )
            }
        }
    }
    
    // MARK: - Add Participants Section
    
    private var addParticipantsSection: some View {
        Section {
            Button("Dodaj uczestników") {
                showingAddParticipants = true
            }
            .foregroundColor(AirLinkColors.primary)
        }
    }
    
    // MARK: - Chat Actions Section
    
    private var chatActionsSection: some View {
        Section {
            Button(chat.isMuted ? "Wyłącz wyciszenie" : "Wycisz grupę") {
                toggleMute()
            }
            .foregroundColor(AirLinkColors.primary)
            
            Button("Wyczyść historię") {
                clearHistory()
            }
            .foregroundColor(AirLinkColors.primary)
            
            if chat.isGroup {
                Button("Opuść grupę") {
                    leaveGroup()
                }
                .foregroundColor(AirLinkColors.statusError)
            } else {
                Button("Usuń czat") {
                    deleteChat()
                }
                .foregroundColor(AirLinkColors.statusError)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var groupStatusText: String {
        let totalCount = participants.count
        let onlineCount = onlineParticipants.count
        
        if onlineCount == 0 {
            return "\(totalCount) uczestników • Wszyscy offline"
        } else if onlineCount == totalCount {
            return "\(totalCount) uczestników • Wszyscy online"
        } else {
            return "\(totalCount) uczestników • \(onlineCount) online"
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
    
    private func openParticipantDetails(_ participant: Contact) {
        coordinator.openContactDetails(participant)
    }
    
    private func showRemoveConfirmation(for participant: Contact) {
        participantToRemove = participant
        showingRemoveConfirmation = true
    }
    
    private func removeParticipant(_ participant: Contact) {
        Task {
            do {
                try await chatService.removeParticipant(participant, from: chat)
            } catch {
                print("Failed to remove participant: \(error)")
            }
        }
    }
    
    private func toggleMute() {
        Task {
            try await chatService.toggleMute(for: chat)
        }
    }
    
    private func clearHistory() {
        Task {
            try await chatService.clearHistory(for: chat)
        }
    }
    
    private func leaveGroup() {
        Task {
            try await chatService.leaveGroup(chat)
            onDismiss()
        }
    }
    
    private func deleteChat() {
        Task {
            try await chatService.deleteChat(chat)
            onDismiss()
        }
    }
}

// MARK: - Participant Row

private struct ParticipantRow: View {
    
    let participant: Contact
    let isOnline: Bool
    let isCurrentUser: Bool
    let canRemove: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                // Avatar
                AvatarView.contact(
                    participant,
                    size: .medium,
                    showStatus: isOnline
                )
                
                // Participant info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(participant.nickname)
                            .font(AppTheme.current.typography.body)
                            .foregroundColor(AirLinkColors.textPrimary)
                        
                        if isCurrentUser {
                            Text("(Ty)")
                                .font(AppTheme.current.typography.caption)
                                .foregroundColor(AirLinkColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(participantStatusText)
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(statusColor)
                }
                
                // Signal indicator
                if isOnline {
                    SignalIndicator.compact(
                        strength: participant.signalStrength,
                        isMesh: participant.isConnectedViaMesh
                    )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if canRemove {
                Button("Usuń", role: .destructive) {
                    onRemove()
                }
            }
        }
        .contextMenu {
            if !isCurrentUser {
                Button("Otwórz profil") {
                    onTap()
                }
                
                if canRemove {
                    Divider()
                    
                    Button("Usuń z grupy", role: .destructive) {
                        onRemove()
                    }
                }
            }
        }
    }
    
    private var participantStatusText: String {
        if isOnline {
            let signalText = participant.signalStrength > 0 ? " • \(participant.signalStrength)/5" : ""
            let meshText = participant.isConnectedViaMesh ? " • Mesh" : ""
            return "Online\(signalText)\(meshText)"
        } else {
            return participant.lastSeenText
        }
    }
    
    private var statusColor: Color {
        isOnline ? AirLinkColors.statusSuccess : AirLinkColors.textTertiary
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
                    .fill(AirLinkColors.statusSuccess)
                    .frame(width: size.indicatorSize, height: size.indicatorSize)
                    .overlay(
                        Circle()
                            .stroke(AirLinkColors.background, lineWidth: 2)
                    )
                    .offset(x: size.indicatorOffset.x, y: size.indicatorOffset.y)
            }
        }
    }
    
    private var groupGradient: LinearGradient {
        let groupName = participants.first?.nickname ?? "Group"
        return AirLinkColors.avatarGradient(for: groupName)
    }
}

// MARK: - Add Participants Sheet

private struct AddParticipantsSheet: View {
    
    let chat: Chat
    let existingParticipants: [Contact]
    let onDismiss: () -> Void
    
    @Environment(ContactService.self) private var contactService
    @Environment(ChatService.self) private var chatService
    
    @State private var selectedContacts: Set<String> = []
    
    var body: some View {
        NavigationView {
            List {
                Section("Dodaj do grupy") {
                    ForEach(availableContacts) { contact in
                        ContactSelectionRow(
                            contact: contact,
                            isSelected: selectedContacts.contains(contact.id),
                            onToggle: { toggleSelection(contact) }
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Dodaj uczestników")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dodaj") {
                        addSelectedParticipants()
                    }
                    .disabled(selectedContacts.isEmpty)
                }
            }
        }
    }
    
    private var availableContacts: [Contact] {
        contactService.contacts.filter { contact in
            !existingParticipants.contains(contact)
        }
    }
    
    private func toggleSelection(_ contact: Contact) {
        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }
    
    private func addSelectedParticipants() {
        let contactsToAdd = availableContacts.filter { selectedContacts.contains($0.id) }
        
        Task {
            do {
                for contact in contactsToAdd {
                    try await chatService.addParticipant(contact, to: chat)
                }
                
                await MainActor.run {
                    onDismiss()
                }
            } catch {
                print("Failed to add participants: \(error)")
            }
        }
    }
}

// MARK: - Contact Selection Row

private struct ContactSelectionRow: View {
    
    let contact: Contact
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AirLinkColors.primary : AirLinkColors.textTertiary)
                
                // Contact info
                AvatarView.contact(contact, size: .medium, showStatus: true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.nickname)
                        .font(AppTheme.current.typography.body)
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    Text(contact.isOnline ? "Online" : contact.lastSeenText)
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(contact.isOnline ? AirLinkColors.statusSuccess : AirLinkColors.textTertiary)
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ParticipantsList(
        chat: Chat.sampleGroupChat,
        participants: [Contact.sampleOnlineContact, Contact.sampleMeshContact, Contact.sampleOfflineContact],
        onlineParticipants: [Contact.sampleOnlineContact, Contact.sampleMeshContact],
        onDismiss: {}
    )
    .withAppTheme()
}
