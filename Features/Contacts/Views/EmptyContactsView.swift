//
//  EmptyContactsView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - EmptyContactsView

/// Widok pustego stanu dla listy kontaktów
/// Wyświetla instrukcje i akcje dla nowych użytkowników
struct EmptyContactsView: View {
    
    // MARK: - Properties
    
    let onScanQR: () -> Void
    let onShowQR: () -> Void
    
    // MARK: - Environment
    
    @Environment(ConnectivityService.self) private var connectivityService
    
    // MARK: - State
    
    @State private var isAnimating = false
    @State private var currentStep = 0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: AppTheme.current.spacing.xl) {
            
            // Main illustration
            illustrationView
            
            // Title and description
            textContent
            
            // Action buttons
            actionButtons
            
            // Steps guide
            stepsGuide
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.current.spacing.lg)
        .padding(.top, AppTheme.current.spacing.xxl)
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Illustration View
    
    private var illustrationView: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            ZStack {
                // Background circles
                Circle()
                    .fill(AirLinkColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Circle()
                    .fill(AirLinkColors.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isAnimating ? 0.8 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3),
                        value: isAnimating
                    )
                
                // Main icon
                Image(systemName: "person.2.circle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(AirLinkColors.primary)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.1),
                        value: isAnimating
                    )
            }
            
            // Connection status
            connectionStatusBadge
        }
    }
    
    // MARK: - Connection Status Badge
    
    private var connectionStatusBadge: some View {
        HStack(spacing: AppTheme.current.spacing.xs) {
            Circle()
                .fill(connectivityService.isActive ? AirLinkColors.statusSuccess : AirLinkColors.statusError)
                .frame(width: 8, height: 8)
            
            Text(connectivityService.isActive ? "Gotowy do połączenia" : "Offline")
                .font(AppTheme.current.typography.caption)
                .foregroundColor(AirLinkColors.textSecondary)
        }
        .padding(.horizontal, AppTheme.current.spacing.sm)
        .padding(.vertical, AppTheme.current.spacing.xs)
        .background(
            Capsule()
                .fill(AirLinkColors.backgroundTertiary)
        )
    }
    
    // MARK: - Text Content
    
    private var textContent: some View {
        VStack(spacing: AppTheme.current.spacing.sm) {
            Text("Dodaj pierwszego kontaktu")
                .font(AppTheme.current.typography.title2)
                .foregroundColor(AirLinkColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Skanuj kod QR znajomego lub poproś go o zeskanowanie Twojego kodu, żeby rozpocząć rozmowę")
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            // Primary action - Scan QR
            Button(action: onScanQR) {
                HStack(spacing: AppTheme.current.spacing.sm) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Skanuj kod QR")
                        .font(AppTheme.current.typography.buttonText)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                        .fill(AirLinkColors.primary)
                )
            }
            .scaleEffect(isAnimating ? 1.02 : 1.0)
            .animation(
                .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: isAnimating
            )
            
            // Secondary action - Show QR
            Button(action: onShowQR) {
                HStack(spacing: AppTheme.current.spacing.sm) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Pokaż mój kod")
                        .font(AppTheme.current.typography.buttonText)
                        .fontWeight(.medium)
                }
                .foregroundColor(AirLinkColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                        .stroke(AirLinkColors.primary, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                                .fill(AirLinkColors.background)
                        )
                )
            }
        }
    }
    
    // MARK: - Steps Guide
    
    private var stepsGuide: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Jak to działa?")
                .font(AppTheme.current.typography.headline)
                .foregroundColor(AirLinkColors.textPrimary)
            
            VStack(spacing: AppTheme.current.spacing.sm) {
                StepRow(
                    number: 1,
                    title: "Skanuj kod QR",
                    description: "Znajdź znajomego i zeskanuj jego kod QR",
                    isActive: currentStep == 0
                )
                
                StepRow(
                    number: 2,
                    title: "Automatyczne połączenie",
                    description: "AirLink automatycznie nawiąże połączenie",
                    isActive: currentStep == 1
                )
                
                StepRow(
                    number: 3,
                    title: "Rozpocznij rozmowę",
                    description: "Wysyłaj wiadomości bez internetu!",
                    isActive: currentStep == 2
                )
            }
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
        .onReceive(Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentStep = (currentStep + 1) % 3
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnimation() {
        withAnimation {
            isAnimating = true
        }
    }
}

// MARK: - Step Row

private struct StepRow: View {
    
    let number: Int
    let title: String
    let description: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            // Step number
            ZStack {
                Circle()
                    .fill(isActive ? AirLinkColors.primary : AirLinkColors.backgroundTertiary)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(isActive ? .white : AirLinkColors.textTertiary)
            }
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(AppTheme.current.animations.spring, value: isActive)
            
            // Step content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(isActive ? AirLinkColors.textPrimary : AirLinkColors.textSecondary)
                    .fontWeight(isActive ? .semibold : .regular)
                
                Text(description)
                    .font(AppTheme.current.typography.caption)
                    .foregroundColor(AirLinkColors.textTertiary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .opacity(isActive ? 1.0 : 0.7)
        .animation(AppTheme.current.animations.medium, value: isActive)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        EmptyContactsView(
            onScanQR: { print("Scan QR tapped") },
            onShowQR: { print("Show QR tapped") }
        )
    }
    .withAppTheme()
}

#Preview("Offline State") {
    NavigationView {
        EmptyContactsView(
            onScanQR: { print("Scan QR tapped") },
            onShowQR: { print("Show QR tapped") }
        )
    }
    .withAppTheme()
    .environment(ConnectivityService())  // Offline service
}
