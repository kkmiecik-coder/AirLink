//
//  AddContactSheet.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - AddContactSheet

/// Sheet potwierdzający dodanie nowego kontaktu
/// Wyświetla informacje o kontakcie i pozwala na dodanie go do listy
struct AddContactSheet: View {
    
    // MARK: - Properties
    
    let contactData: ContactQRData
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    // MARK: - Environment
    
    @Environment(ContactService.self) private var contactService
    
    // MARK: - State
    
    @State private var customNickname: String = ""
    @State private var useCustomNickname = false
    @State private var isAdding = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.current.spacing.xl) {
                
                // Header
                headerSection
                
                // Contact preview
                contactPreviewSection
                
                // Nickname customization
                nicknameSection
                
                // Connection info
                connectionInfoSection
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .padding(.horizontal, AppTheme.current.spacing.lg)
            .padding(.top, AppTheme.current.spacing.lg)
            .navigationTitle("Dodaj kontakt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        onCancel()
                    }
                }
            }
        }
        .onAppear {
            customNickname = contactData.nickname
        }
        .alert("Błąd", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(AirLinkColors.primary)
            
            Text("Nowy kontakt")
                .font(AppTheme.current.typography.title2)
                .foregroundColor(AirLinkColors.textPrimary)
            
            Text("Zeskanowano dane kontaktu z kodu QR")
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Contact Preview Section
    
    private var contactPreviewSection: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            // Avatar
            AvatarView.text(
                useCustomNickname ? customNickname : contactData.nickname,
                size: .extraLarge
            )
            
            // Contact info
            VStack(spacing: AppTheme.current.spacing.xs) {
                Text(useCustomNickname ? customNickname : contactData.nickname)
                    .font(AppTheme.current.typography.title3)
                    .foregroundColor(AirLinkColors.textPrimary)
                    .fontWeight(.semibold)
                
                Text("AirLink User")
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                
                // Status badges
                HStack(spacing: AppTheme.current.spacing.sm) {
                    StatusBadge(
                        text: "Gotowy do połączenia",
                        color: AirLinkColors.statusSuccess,
                        icon: "checkmark.circle.fill"
                    )
                    
                    if contactData.hasAvatar {
                        StatusBadge(
                            text: "Ma zdjęcie",
                            color: AirLinkColors.primary,
                            icon: "photo.circle.fill"
                        )
                    }
                }
            }
        }
        .padding(AppTheme.current.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Nickname Section
    
    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Toggle("Dostosuj pseudonim", isOn: $useCustomNickname)
                .font(AppTheme.current.typography.headline)
                .tint(AirLinkColors.primary)
            
            if useCustomNickname {
                VStack(alignment: .leading, spacing: AppTheme.current.spacing.xs) {
                    Text("Własny pseudonim")
                        .font(AppTheme.current.typography.body)
                        .foregroundColor(AirLinkColors.textSecondary)
                    
                    TextField("Wprowadź pseudonim", text: $customNickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.done)
                    
                    Text("Możesz zmienić jak będzie wyświetlane imię tego kontaktu")
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(AirLinkColors.textTertiary)
                }
                .padding(.top, AppTheme.current.spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
        .animation(AppTheme.current.animations.medium, value: useCustomNickname)
    }
    
    // MARK: - Connection Info Section
    
    private var connectionInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Informacje o połączeniu")
                .font(AppTheme.current.typography.headline)
                .foregroundColor(AirLinkColors.textPrimary)
            
            VStack(spacing: AppTheme.current.spacing.sm) {
                InfoRow(
                    icon: "network",
                    title: "ID urządzenia",
                    value: String(contactData.id.prefix(8)) + "...",
                    color: AirLinkColors.primary
                )
                
                InfoRow(
                    icon: "info.circle",
                    title: "Wersja protokołu",
                    value: "v\(contactData.version)",
                    color: AirLinkColors.statusSuccess
                )
                
                InfoRow(
                    icon: "wifi",
                    title: "Status",
                    value: "Oczekuje na połączenie",
                    color: AirLinkColors.statusWarning
                )
            }
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            Button(action: addContact) {
                HStack {
                    if isAdding {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isAdding ? "Dodawanie..." : "Dodaj kontakt")
                        .font(AppTheme.current.typography.buttonText)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                        .fill(canAddContact ? AirLinkColors.primary : AirLinkColors.textTertiary)
                )
            }
            .disabled(!canAddContact || isAdding)
            
            Button("Anuluj") {
                onCancel()
            }
            .font(AppTheme.current.typography.buttonText)
            .foregroundColor(AirLinkColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .padding(.bottom, AppTheme.current.spacing.lg)
    }
    
    // MARK: - Computed Properties
    
    private var canAddContact: Bool {
        let nickname = useCustomNickname ? customNickname : contactData.nickname
        return !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !contactExists()
    }
    
    // MARK: - Helper Methods
    
    private func contactExists() -> Bool {
        return contactService.findContact(by: contactData.id) != nil
    }
    
    private func addContact() {
        guard canAddContact else { return }
        
        isAdding = true
        
        let finalNickname = useCustomNickname ? customNickname.trimmingCharacters(in: .whitespacesAndNewlines) : contactData.nickname
        
        Task {
            do {
                let updatedContactData = ContactQRData(
                    id: contactData.id,
                    nickname: finalNickname,
                    hasAvatar: contactData.hasAvatar,
                    version: contactData.version
                )
                
                _ = try await contactService.addContact(from: updatedContactData)
                
                await MainActor.run {
                    isAdding = false
                    onConfirm()
                }
                
                // Haptic feedback
                HapticManager.shared.notification(.success)
                
            } catch {
                await MainActor.run {
                    isAdding = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                
                // Error haptic
                HapticManager.shared.notification(.error)
            }
        }
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.xs) {
            Image(systemName: icon)
                .font(.caption2.weight(.medium))
            
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, AppTheme.current.spacing.xs)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    AddContactSheet(
        contactData: ContactQRData(
            id: "sample-device-id-12345",
            nickname: "Jan Kowalski",
            hasAvatar: true,
            version: 1
        ),
        onConfirm: { print("Contact added") },
        onCancel: { print("Cancelled") }
    )
    .withAppTheme()
    .environment(ContactService.createMockService())
}

#Preview("Long Nickname") {
    AddContactSheet(
        contactData: ContactQRData(
            id: "sample-device-id-67890",
            nickname: "Anna Maria Kowalska-Nowak",
            hasAvatar: false,
            version: 1
        ),
        onConfirm: { print("Contact added") },
        onCancel: { print("Cancelled") }
    )
    .withAppTheme()
    .environment(ContactService.createMockService())
}
