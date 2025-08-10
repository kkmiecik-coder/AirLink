//
//  ContactDetails.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - ContactDetails

/// Szczegółowy widok kontaktu z informacjami i opcjami zarządzania
/// Wyświetla profil, status połączenia, historię i akcje
struct ContactDetails: View {
    
    // MARK: - Properties
    
    let contact: Contact
    let onDismiss: () -> Void
    
    // MARK: - Environment
    
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(ContactService.self) private var contactService
    @Environment(ChatService.self) private var chatService
    
    // MARK: - State
    
    @State private var showingDeleteConfirmation = false
    @State private var showingEditContact = false
    @State private var isCreatingChat = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.current.spacing.lg) {
                    
                    // Profile header
                    profileHeader
                    
                    // Connection info
                    connectionInfoSection
                    
                    // Contact actions
                    contactActionsSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Danger zone
                    dangerZoneSection
                }
                .padding(.horizontal, AppTheme.current.spacing.md)
                .padding(.top, AppTheme.current.spacing.lg)
            }
            .navigationTitle("Kontakt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zamknij") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edytuj") {
                        showingEditContact = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditContact) {
            EditContactSheet(
                contact: contact,
                onDismiss: { showingEditContact = false }
            )
        }
        .confirmationDialog(
            "Usuń kontakt",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Usuń kontakt", role: .destructive) {
                deleteContact()
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Czy na pewno chcesz usunąć \(contact.nickname) ze swoich kontaktów? Ta akcja nie może zostać cofnięta.")
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            // Large avatar
            AvatarView.contact(
                contact,
                size: .extraLarge,
                showStatus: true
            )
            
            // Name and status
            VStack(spacing: AppTheme.current.spacing.xs) {
                Text(contact.nickname)
                    .font(AppTheme.current.typography.title2)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text(connectionStatusText)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(connectionStatusColor)
            }
            
            // Signal strength (if online)
            if contact.isOnline {
                SignalIndicator.large(
                    strength: contact.signalStrength,
                    isMesh: contact.isConnectedViaMesh
                )
            }
        }
        .padding(.vertical, AppTheme.current.spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusLarge)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Connection Info Section
    
    private var connectionInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Informacje o połączeniu")
                .sectionHeaderStyle()
            
            LazyVStack(spacing: AppTheme.current.spacing.sm) {
                InfoRow(
                    title: "Status",
                    value: contact.isOnline ? "Online" : "Offline",
                    icon: "wifi",
                    color: contact.isOnline ? AirLinkColors.statusSuccess : AirLinkColors.textTertiary
                )
                
                if contact.isOnline {
                    InfoRow(
                        title: "Siła sygnału",
                        value: "\(contact.signalStrength)/5",
                        icon: "antenna.radiowaves.left.and.right",
                        color: AirLinkColors.signalColor(for: contact.signalStrength)
                    )
                    
                    InfoRow(
                        title: "Typ połączenia",
                        value: contact.isConnectedViaMesh ? "Mesh Network" : "Bezpośrednie",
                        icon: contact.isConnectedViaMesh ? "network" : "personalhotspot",
                        color: contact.isConnectedViaMesh ? AirLinkColors.statusMesh : AirLinkColors.statusSuccess
                    )
                } else {
                    InfoRow(
                        title: "Ostatnio widziany",
                        value: contact.lastSeenText,
                        icon: "clock",
                        color: AirLinkColors.textTertiary
                    )
                }
                
                InfoRow(
                    title: "ID urządzenia",
                    value: String(contact.deviceID.prefix(8)) + "...",
                    icon: "network",
                    color: AirLinkColors.textSecondary
                )
            }
            .padding(AppTheme.current.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                    .fill(AirLinkColors.backgroundSecondary)
            )
        }
    }
    
    // MARK: - Contact Actions Section
    
    private var contactActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Akcje")
                .sectionHeaderStyle()
            
            LazyVStack(spacing: 0) {
                ActionRow(
                    title: "Wyślij wiadomość",
                    icon: "message",
                    color: AirLinkColors.primary,
                    isLoading: isCreatingChat
                ) {
                    createDirectMessage()
                }
                
                Divider()
                    .padding(.leading, 44)
                
                ActionRow(
                    title: "Zadzwoń",
                    icon: "phone",
                    color: AirLinkColors.statusSuccess,
                    isDisabled: !contact.isOnline
                ) {
                    // TODO: Implement voice call
                    print("Call contact: \(contact.nickname)")
                }
                
                Divider()
                    .padding(.leading, 44)
                
                ActionRow(
                    title: "Udostępnij kontakt",
                    icon: "square.and.arrow.up",
                    color: AirLinkColors.primary
                ) {
                    shareContact()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                    .fill(AirLinkColors.backgroundSecondary)
            )
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Statystyki")
                .sectionHeaderStyle()
            
            LazyVStack(spacing: AppTheme.current.spacing.sm) {
                StatisticCard(
                    title: "Wiadomości",
                    value: "\(contact.messageCount)",
                    icon: "message.badge",
                    color: AirLinkColors.primary
                )
                
                StatisticCard(
                    title: "Zdjęcia",
                    value: "\(contact.sharedPhotosCount)",
                    icon: "photo.stack",
                    color: AirLinkColors.statusWarning
                )
                
                StatisticCard(
                    title: "Czas online",
                    value: contact.totalOnlineTime,
                    icon: "clock.badge",
                    color: AirLinkColors.statusSuccess
                )
            }
        }
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Zarządzanie kontaktem")
                .sectionHeaderStyle()
            
            LazyVStack(spacing: 0) {
                ActionRow(
                    title: "Zablokuj kontakt",
                    icon: "person.crop.circle.badge.minus",
                    color: AirLinkColors.statusWarning
                ) {
                    blockContact()
                }
                
                Divider()
                    .padding(.leading, 44)
                
                ActionRow(
                    title: "Usuń kontakt",
                    icon: "trash",
                    color: AirLinkColors.statusError
                ) {
                    showingDeleteConfirmation = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                    .fill(AirLinkColors.backgroundSecondary)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusText: String {
        if contact.isOnline {
            let signalText = contact.signalStrength > 0 ? " • \(contact.signalStrength)/5" : ""
            let meshText = contact.isConnectedViaMesh ? " • Mesh" : ""
            return "Online\(signalText)\(meshText)"
        } else {
            return contact.lastSeenText
        }
    }
    
    private var connectionStatusColor: Color {
        contact.isOnline ? AirLinkColors.statusSuccess : AirLinkColors.textTertiary
    }
    
    // MARK: - Actions
    
    private func createDirectMessage() {
        isCreatingChat = true
        
        Task {
            do {
                let chat = try await chatService.createDirectMessageChat(with: contact)
                
                await MainActor.run {
                    isCreatingChat = false
                    onDismiss()
                    coordinator.openChat(chat)
                }
            } catch {
                await MainActor.run {
                    isCreatingChat = false
                    print("Failed to create chat: \(error)")
                }
            }
        }
    }
    
    private func shareContact() {
        // TODO: Implement contact sharing
        print("Share contact: \(contact.nickname)")
    }
    
    private func blockContact() {
        Task {
            try await contactService.blockContact(contact)
        }
    }
    
    private func deleteContact() {
        Task {
            do {
                try await contactService.deleteContact(contact)
                
                await MainActor.run {
                    onDismiss()
                }
            } catch {
                print("Failed to delete contact: \(error)")
            }
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Action Row

private struct ActionRow: View {
    
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String,
        color: Color,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDisabled ? AirLinkColors.textTertiary : color)
                        .frame(width: 24, height: 24)
                        .opacity(isLoading ? 0 : 1)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: color))
                            .scaleEffect(0.7)
                    }
                }
                
                Text(title)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(isDisabled ? AirLinkColors.textTertiary : AirLinkColors.textPrimary)
                
                Spacer()
                
                if !isLoading && !isDisabled {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AirLinkColors.textTertiary)
                }
            }
            .padding(.horizontal, AppTheme.current.spacing.md)
            .padding(.vertical, AppTheme.current.spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Statistic Card

private struct StatisticCard: View {
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.current.typography.caption)
                    .foregroundColor(AirLinkColors.textSecondary)
                
                Text(value)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textPrimary)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(AppTheme.current.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundTertiary)
        )
    }
}

// MARK: - Edit Contact Sheet

private struct EditContactSheet: View {
    
    let contact: Contact
    let onDismiss: () -> Void
    
    @Environment(ContactService.self) private var contactService
    
    @State private var nickname: String
    @State private var isSaving = false
    
    init(contact: Contact, onDismiss: @escaping () -> Void) {
        self.contact = contact
        self.onDismiss = onDismiss
        self._nickname = State(initialValue: contact.nickname)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informacje kontaktu") {
                    HStack {
                        Text("Pseudonim")
                        TextField("Wprowadź pseudonim", text: $nickname)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Avatar") {
                    HStack {
                        AvatarView.simple(contact, size: .medium)
                        
                        VStack(alignment: .leading) {
                            Text("Zdjęcie profilowe")
                                .font(AppTheme.current.typography.body)
                            
                            Text("Automatycznie generowane")
                                .font(AppTheme.current.typography.caption)
                                .foregroundColor(AirLinkColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button("Zmień") {
                            // TODO: Implement avatar change
                        }
                        .font(AppTheme.current.typography.buttonSmall)
                    }
                }
            }
            .navigationTitle("Edytuj kontakt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zapisz") {
                        saveChanges()
                    }
                    .disabled(nickname.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        Task {
            do {
                try await contactService.updateContact(contact, nickname: nickname)
                
                await MainActor.run {
                    isSaving = false
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    print("Failed to save contact changes: \(error)")
                }
            }
        }
    }
}

// MARK: - Extensions

extension Contact {
    
    /// Liczba wiadomości z tym kontaktem
    var messageCount: Int {
        // TODO: Implement message count calculation
        return Int.random(in: 10...500)
    }
    
    /// Liczba udostępnionych zdjęć
    var sharedPhotosCount: Int {
        // TODO: Implement shared photos count
        return Int.random(in: 0...50)
    }
    
    /// Sformatowany czas online
    var totalOnlineTime: String {
        // TODO: Implement online time calculation
        let hours = Int.random(in: 1...100)
        return "\(hours)h"
    }
}

// MARK: - Preview

#Preview {
    ContactDetails(
        contact: Contact.sampleOnlineContact,
        onDismiss: {}
    )
    .withAppTheme()
}

#Preview("Offline Contact") {
    ContactDetails(
        contact: Contact.sampleOfflineContact,
        onDismiss: {}
    )
    .withAppTheme()
}
