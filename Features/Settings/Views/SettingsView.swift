//
//  SettingsView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - SettingsView

/// Główny ekran ustawień aplikacji AirLink
/// Zawiera opcje profilu, prywatności, pamięci i informacje o aplikacji
struct SettingsView: View {
    
    // MARK: - Environment
    
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(NavigationCoordinator.self) private var coordinator
    
    // MARK: - State
    
    @State private var showingProfileSetup = false
    @State private var showingPrivacyInfo = false
    @State private var showingStorageInfo = false
    @State private var showingQRDisplay = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Profile section
                profileSection
                
                // QR Code section
                qrCodeSection
                
                // Privacy & Security section
                privacySection
                
                // Storage section
                storageSection
                
                // About section
                aboutSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Ustawienia")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingProfileSetup) {
            ProfileSetup()
        }
        .sheet(isPresented: $showingPrivacyInfo) {
            PrivacyInfo()
        }
        .sheet(isPresented: $showingStorageInfo) {
            StorageInfo()
        }
        .sheet(isPresented: $showingQRDisplay) {
            QRDisplayView()
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section("Profil") {
            Button(action: { showingProfileSetup = true }) {
                HStack(spacing: AppTheme.current.spacing.md) {
                    // Avatar
                    if let avatarImage = viewModel.userAvatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AirLinkColors.avatarGradient(for: viewModel.userNickname))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(viewModel.userNickname.prefix(1).uppercased()))
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // User info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.userNickname)
                            .font(AppTheme.current.typography.headline)
                            .foregroundColor(AirLinkColors.textPrimary)
                        
                        Text("Dotknij, żeby edytować")
                            .font(AppTheme.current.typography.body)
                            .foregroundColor(AirLinkColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AirLinkColors.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - QR Code Section
    
    private var qrCodeSection: some View {
        Section("Kod QR") {
            Button(action: { showingQRDisplay = true }) {
                HStack {
                    Image(systemName: "qrcode")
                        .font(.title3)
                        .foregroundColor(AirLinkColors.primary)
                        .frame(width: 24)
                    
                    Text("Pokaż mój kod QR")
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AirLinkColors.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section("Prywatność i bezpieczeństwo") {
            Button(action: { showingPrivacyInfo = true }) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.title3)
                        .foregroundColor(AirLinkColors.statusSuccess)
                        .frame(width: 24)
                    
                    Text("Informacje o prywatności")
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AirLinkColors.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        Section("Pamięć") {
            Button(action: { showingStorageInfo = true }) {
                HStack {
                    Image(systemName: "externaldrive")
                        .font(.title3)
                        .foregroundColor(AirLinkColors.statusWarning)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zarządzanie pamięcią")
                            .foregroundColor(AirLinkColors.textPrimary)
                        
                        Text(viewModel.formatStorageSize(viewModel.storageStats.usedSpace))
                            .font(AppTheme.current.typography.caption)
                            .foregroundColor(AirLinkColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if viewModel.isCleanupRecommended {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(AirLinkColors.statusWarning)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AirLinkColors.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("O aplikacji") {
            VStack(alignment: .leading, spacing: AppTheme.current.spacing.sm) {
                HStack {
                    Text("AirLink")
                        .font(AppTheme.current.typography.headline)
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    Spacer()
                    
                    Text("v\(AppConstants.appVersion)")
                        .font(AppTheme.current.typography.body)
                        .foregroundColor(AirLinkColors.textSecondary)
                }
                
                Text("Komunikacja bez internetu przez mesh network")
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: AppTheme.current.spacing.md) {
                    StatusIndicator(
                        icon: "wifi.slash",
                        text: "Bez internetu",
                        color: AirLinkColors.statusSuccess
                    )
                    
                    StatusIndicator(
                        icon: "lock.fill",
                        text: "Szyfrowane",
                        color: AirLinkColors.statusSuccess
                    )
                    
                    StatusIndicator(
                        icon: "icloud.slash",
                        text: "Lokalne",
                        color: AirLinkColors.statusSuccess
                    )
                }
                .padding(.top, AppTheme.current.spacing.xs)
            }
            .padding(.vertical, AppTheme.current.spacing.xs)
        }
    }
}

// MARK: - Status Indicator

private struct StatusIndicator: View {
    
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.medium))
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .withAppTheme()
        .environment(SettingsViewModel.createMockViewModel())
        .environment(NavigationCoordinator.createMockCoordinator())
}
