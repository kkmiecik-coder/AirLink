//
//  QRDisplayView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - QRDisplayView

/// Widok wyświetlający kod QR użytkownika do skanowania przez innych
/// Umożliwia udostępnienie danych kontaktowych przez kod QR
struct QRDisplayView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(QRService.self) private var qrService
    @Environment(SettingsViewModel.self) private var settingsViewModel
    
    // MARK: - State
    
    @State private var isGenerating = true
    @State private var qrImage: UIImage?
    @State private var showingShareSheet = false
    @State private var brightness: Double = 1.0
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.current.spacing.xl) {
                
                // Header
                headerSection
                
                // QR Code
                qrCodeSection
                
                // User info
                userInfoSection
                
                // Actions
                actionsSection
                
                // Instructions
                instructionsSection
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.current.spacing.lg)
            .padding(.top, AppTheme.current.spacing.lg)
            .navigationTitle("Mój kod QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zamknij") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Udostępnij kod") {
                            showingShareSheet = true
                        }
                        
                        Button("Zapisz do zdjęć") {
                            saveToPhotos()
                        }
                        
                        Button("Regeneruj kod") {
                            regenerateQR()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            generateQRCode()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let qrImage = qrImage {
                ShareSheet(items: [qrImage])
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: "qrcode")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(AirLinkColors.primary)
            
            Text("Pokaż swój kod QR")
                .font(AppTheme.current.typography.title2)
                .foregroundColor(AirLinkColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Poproś znajomego o zeskanowanie tego kodu, żeby się połączyć")
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - QR Code Section
    
    private var qrCodeSection: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                    .fill(Color.white)
                    .frame(width: 280, height: 280)
                    .shadow(
                        color: AirLinkColors.shadowMedium,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                if isGenerating {
                    // Loading state
                    VStack(spacing: AppTheme.current.spacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AirLinkColors.primary))
                            .scaleEffect(1.5)
                        
                        Text("Generowanie kodu...")
                            .font(AppTheme.current.typography.body)
                            .foregroundColor(AirLinkColors.textSecondary)
                    }
                } else if let qrImage = qrImage {
                    // QR Code
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 240, height: 240)
                        .brightness(brightness - 1.0)
                } else {
                    // Error state
                    VStack(spacing: AppTheme.current.spacing.sm) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundColor(AirLinkColors.statusError)
                        
                        Text("Błąd generowania kodu")
                            .font(AppTheme.current.typography.body)
                            .foregroundColor(AirLinkColors.textSecondary)
                        
                        Button("Spróbuj ponownie") {
                            regenerateQR()
                        }
                        .font(AppTheme.current.typography.buttonSmall)
                        .foregroundColor(AirLinkColors.primary)
                    }
                }
            }
            
            // Brightness control
            if !isGenerating && qrImage != nil {
                brightnessControl
            }
        }
    }
    
    // MARK: - Brightness Control
    
    private var brightnessControl: some View {
        VStack(spacing: AppTheme.current.spacing.xs) {
            Text("Jasność")
                .font(AppTheme.current.typography.caption)
                .foregroundColor(AirLinkColors.textSecondary)
            
            HStack(spacing: AppTheme.current.spacing.sm) {
                Image(systemName: "sun.min")
                    .font(.caption)
                    .foregroundColor(AirLinkColors.textTertiary)
                
                Slider(value: $brightness, in: 0.5...1.5)
                    .accentColor(AirLinkColors.primary)
                
                Image(systemName: "sun.max")
                    .font(.caption)
                    .foregroundColor(AirLinkColors.textTertiary)
            }
        }
        .padding(.horizontal, AppTheme.current.spacing.md)
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        HStack(spacing: AppTheme.current.spacing.md) {
            // Avatar
            AvatarView.simple(nil, size: .large)
                .overlay(
                    if let avatarImage = settingsViewModel.userAvatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AirLinkColors.avatarGradient(for: settingsViewModel.userNickname))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(settingsViewModel.userNickname.prefix(1).uppercased()))
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                            )
                    }
                )
            
            // User details
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsViewModel.userNickname)
                    .font(AppTheme.current.typography.title3)
                    .foregroundColor(AirLinkColors.textPrimary)
                    .fontWeight(.semibold)
                
                Text("AirLink User")
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                
                HStack(spacing: AppTheme.current.spacing.xs) {
                    Circle()
                        .fill(AirLinkColors.statusSuccess)
                        .frame(width: 8, height: 8)
                    
                    Text("Gotowy do połączenia")
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(AirLinkColors.statusSuccess)
                }
            }
            
            Spacer()
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: AppTheme.current.spacing.md) {
            // Share button
            Button(action: { showingShareSheet = true }) {
                HStack(spacing: AppTheme.current.spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Udostępnij")
                        .font(AppTheme.current.typography.buttonText)
                        .fontWeight(.medium)
                }
                .foregroundColor(AirLinkColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                        .stroke(AirLinkColors.primary, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                                .fill(AirLinkColors.primaryOpacity10)
                        )
                )
            }
            .disabled(qrImage == nil)
            
            // Save button
            Button(action: saveToPhotos) {
                HStack(spacing: AppTheme.current.spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Zapisz")
                        .font(AppTheme.current.typography.buttonText)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                        .fill(AirLinkColors.primary)
                )
            }
            .disabled(qrImage == nil)
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.sm) {
            Text("Instrukcje")
                .font(AppTheme.current.typography.headline)
                .foregroundColor(AirLinkColors.
