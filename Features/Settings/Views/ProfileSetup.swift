//
//  ProfileSetup.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI
import PhotosUI

// MARK: - ProfileSetup

/// Widok konfiguracji profilu użytkownika
/// Umożliwia ustawienie pseudonimu i zdjęcia profilowego
struct ProfileSetup: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var viewModel
    
    // MARK: - State
    
    @State private var nickname: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingCamera = false
    @State private var isProcessingImage = false
    
    // MARK: - Focus State
    
    @FocusState private var isNicknameFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.current.spacing.xl) {
                    
                    // Header
                    headerSection
                    
                    // Profile picture section
                    profilePictureSection
                    
                    // Nickname section
                    nicknameSection
                    
                    // Guidelines section
                    guidelinesSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, AppTheme.current.spacing.lg)
                .padding(.top, AppTheme.current.spacing.lg)
            }
            .navigationTitle("Konfiguracja profilu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zapisz") {
                        saveProfile()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
        .photosPicker(
            isPresented: Binding(
                get: { selectedPhoto != nil },
                set: { _ in }
            ),
            selection: $selectedPhoto,
            matching: .images
        )
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                profileImage = image
                processProfileImage()
            }
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let newPhoto = newPhoto {
                loadSelectedPhoto(newPhoto)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: "person.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AirLinkColors.primary)
            
            Text("Skonfiguruj swój profil")
                .font(AppTheme.current.typography.title2)
                .foregroundColor(AirLinkColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Wybierz pseudonim i zdjęcie, które będą widoczne dla innych użytkowników")
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Profile Picture Section
    
    private var profilePictureSection: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            Text("Zdjęcie profilowe")
                .font(AppTheme.current.typography.headline)
                .foregroundColor(AirLinkColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: AppTheme.current.spacing.lg) {
                // Current avatar preview
                avatarPreview
                
                // Photo options
                VStack(spacing: AppTheme.current.spacing.sm) {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        photoActionButton(
                            title: "Wybierz z galerii",
                            icon: "photo.on.rectangle"
                        )
                    }
                    
                    Button(action: { showingCamera = true }) {
                        photoActionButton(
                            title: "Zrób zdjęcie",
                            icon: "camera"
                        )
                    }
                    
                    if profileImage != nil {
                        Button(action: removeProfileImage) {
                            photoActionButton(
                                title: "Usuń zdjęcie",
                                icon: "trash",
                                color: AirLinkColors.statusError
                            )
                        }
                    }
                }
            }
            
            Text("Zdjęcie jest opcjonalne. Jeśli nie wybierzesz zdjęcia, zostanie wygenerowany avatar z pierwszej litery Twojego pseudonimu.")
                .font(AppTheme.current.typography.caption)
                .foregroundColor(AirLinkColors.textTertiary)
                .multilineTextAlignment(.leading)
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Avatar Preview
    
    private var avatarPreview: some View {
        ZStack {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AirLinkColors.avatarGradient(for: nickname))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(nickname.isEmpty ? "?" : String(nickname.prefix(1).uppercased()))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            if isProcessingImage {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 80, height: 80)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
        }
        .overlay(
            Circle()
                .stroke(AirLinkColors.borderLight, lineWidth: 2)
        )
    }
    
    // MARK: - Photo Action Button
    
    private func photoActionButton(
        title: String,
        icon: String,
        color: Color = AirLinkColors.primary
    ) -> some View {
        HStack(spacing: AppTheme.current.spacing.xs) {
            Image(systemName: icon)
                .font(.caption.weight(.medium))
            
            Text(title)
                .font(AppTheme.current.typography.buttonSmall)
        }
        .foregroundColor(color)
        .padding(.horizontal, AppTheme.current.spacing.sm)
        .padding(.vertical, AppTheme.current.spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                )
        )
    }
    
    // MARK: - Nickname Section
    
    private var nicknameSection: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.current.spacing.xs) {
                Text("Pseudonim")
                    .font(AppTheme.current.typography.headline)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text("Tak będą Cię widzieć inni użytkownicy")
                    .font(AppTheme.current.typography.caption)
                    .foregroundColor(AirLinkColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Wprowadź pseudonim", text: $nickname)
                .textFieldStyle(AirLinkTextFieldStyle())
                .focused($isNicknameFocused)
                .submitLabel(.done)
                .onSubmit {
                    isNicknameFocused = false
                }
            
            // Character count
            HStack {
                Spacer()
                
                Text("\(nickname.count)/30")
                    .font(AppTheme.current.typography.caption)
                    .foregroundColor(
                        nickname.count > 25 ? AirLinkColors.statusWarning :
                        nickname.count > 30 ? AirLinkColors.statusError :
                        AirLinkColors.textTertiary
                    )
            }
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Guidelines Section
    
    private var guidelinesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.sm) {
            Text("Wskazówki")
                .font(AppTheme.current.typography.headline)
                .foregroundColor(AirLinkColors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppTheme.current.spacing.xs) {
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "Użyj swojego prawdziwego imienia lub znanego pseudonimu",
                    color: AirLinkColors.statusSuccess
                )
                
                GuidelineRow(
                    icon: "person.2.circle.fill",
                    text: "Wybierz pseudonim, który
