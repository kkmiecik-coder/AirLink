//
//  PrivacyInfo.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - PrivacyInfo

/// Widok informacji o prywatności i bezpieczeństwie AirLink
/// Wyjaśnia jak działa aplikacja i jak chroni dane użytkowników
struct PrivacyInfo: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.current.spacing.xl) {
                    
                    // Header
                    headerSection
                    
                    // Core principles
                    principlesSection
                    
                    // How it works
                    howItWorksSection
                    
                    // Data handling
                    dataHandlingSection
                    
                    // Security features
                    securitySection
                    
                    // Permissions
                    permissionsSection
                    
                    // FAQ
                    faqSection
                }
                .padding(.horizontal, AppTheme.current.spacing.lg)
                .padding(.top, AppTheme.current.spacing.lg)
                .padding(.bottom, AppTheme.current.spacing.xxl)
            }
            .navigationTitle("Prywatność")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AirLinkColors.primary)
            
            Text("Twoja prywatność to priorytet")
                .font(AppTheme.current.typography.title2)
                .foregroundColor(AirLinkColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("AirLink został zaprojektowany z myślą o maksymalnej prywatności i bezpieczeństwie Twoich danych")
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Core Principles Section
    
    private var principlesSection: some View {
        InfoSection(
            title: "Podstawowe zasady",
            icon: "heart.fill",
            color: AirLinkColors.statusSuccess
        ) {
            VStack(spacing: AppTheme.current.spacing.md) {
                PrincipleCard(
                    icon: "wifi.slash",
                    title: "Brak internetu = brak śledzenia",
                    description: "Wszystkie dane pozostają na Twoim urządzeniu i nie są wysyłane do żadnych serwerów"
                )
                
                PrincipleCard(
                    icon: "lock.fill",
                    title: "Szyfrowanie end-to-end",
                    description: "Wszystkie wiadomości są szyfrowane i mogą być odczytane tylko przez nadawcę i odbiorcę"
                )
                
                PrincipleCard(
                    icon: "eye.slash.fill",
                    title: "Zero zbierania danych",
                    description: "Nie zbieramy, nie analizujemy i nie sprzedajemy żadnych Twoich danych osobowych"
                )
                
                PrincipleCard(
                    icon: "externaldrive.fill",
                    title: "Lokalne przechowywanie",
                    description: "Wszystkie dane są przechowywane tylko lokalnie na Twoim urządzeniu"
                )
            }
        }
    }
    
    // MARK: - How It Works Section
    
    private var howItWorksSection: some View {
        InfoSection(
            title: "Jak to działa",
            icon: "gearshape.fill",
            color: AirLinkColors.primary
        ) {
            VStack(spacing: AppTheme.current.spacing.md) {
                HowItWorksStep(
                    number: 1,
                    title: "Mesh Network",
                    description: "Urządzenia łączą się bezpośrednio ze sobą przez Bluetooth i Wi-Fi Direct, tworząc lokalną sieć mesh"
                )
                
                HowItWorksStep(
                    number: 2,
                    title: "Bez serwerów",
                    description: "Wiadomości przechodzą bezpośrednio między urządzeniami, bez konieczności przesyłania przez internet lub serwery"
                )
                
                HowItWorksStep(
                    number: 3,
                    title: "Automatyczne routing",
                    description: "Jeśli nie można połączyć się bezpośrednio, wiadomość znajdzie drogę przez inne urządzenia w sieci"
                )
            }
        }
    }
    
    // MARK: - Data Handling Section
    
    private var dataHandlingSection: some View {
        InfoSection(
            title: "Obsługa danych",
            icon: "folder.fill",
            color: AirLinkColors.statusWarning
        ) {
            VStack(alignment: .leading, spacing: AppTheme.current.spacing.sm) {
                DataHandlingRow(
                    category: "Wiadomości",
                    handling: "Przechowywane lokalnie, szyfrowane",
                    retention: "Do momentu usunięcia przez użytkownika"
                )
                
                DataHandlingRow(
                    category: "Kontakty",
                    handling: "Przechowywane lokalnie, opcjonalne",
                    retention: "Do momentu usunięcia przez użytkownika"
                )
                
                DataHandlingRow(
                    category: "Zdjęcia",
                    handling: "Kompresowane i szyfrowane lokalnie",
                    retention: "Do momentu usunięcia przez użytkownika"
                )
                
                DataHandlingRow(
                    category: "Metadane",
                    handling: "Minimalne, tylko do działania aplikacji",
                    retention: "Automatycznie usuwane po 24h"
                )
            }
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        InfoSection(
            title: "Bezpieczeństwo",
            icon: "lock.shield.fill",
            color: AirLinkColors.statusError
        ) {
            VStack(spacing: AppTheme.current.spacing.md) {
                SecurityFeature(
                    icon: "key.fill",
                    title: "Szyfrowanie AES-256",
                    description: "Używamy najwyższego standardu szyfrowania stosowanego przez banki i wojsko"
                )
                
                SecurityFeature(
                    icon: "signature",
                    title: "Podpisy cyfrowe",
                    description: "Każda wiadomość jest podpisana cyfrowo, żeby zapewnić autentyczność nadawcy"
                )
                
                SecurityFeature(
                    icon: "timer",
                    title: "Ephemeral keys",
                    description: "Klucze szyfrowania są generowane na nowo dla każdej sesji"
                )
                
                SecurityFeature(
                    icon: "shield.lefthalf.filled.slash",
                    title: "Forward secrecy",
                    description: "Nawet jeśli klucz zostanie skompromitowany, stare wiadomości pozostaną bezpieczne"
                )
            }
        }
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        InfoSection(
            title: "Uprawnienia",
            icon: "checkmark.shield.fill",
            color: AirLinkColors.primary
        ) {
            VStack(spacing: AppTheme.current.spacing.sm) {
                PermissionRow(
                    permission: "Bluetooth",
                    reason: "Do komunikacji z innymi urządzeniami w pobliżu",
                    required: true
                )
                
                PermissionRow(
                    permission: "Wi-Fi",
                    reason: "Do tworzenia bezpośrednich połączeń między urządzeniami",
                    required: true
                )
                
                PermissionRow(
                    permission: "Kamera",
                    reason: "Do skanowania kodów QR i robienia zdjęć",
                    required: false
                )
                
                PermissionRow(
                    permission: "Galeria zdjęć",
                    reason: "Do wysyłania zdjęć w wiadomościach",
                    required: false
                )
                
                PermissionRow(
                    permission: "Powiadomienia",
                    reason: "Do informowania o nowych wiadomościach",
                    required: false
                )
            }
        }
    }
    
    // MARK: - FAQ Section
    
    private var faqSection: some View {
        InfoSection(
            title: "Często zadawane pytania",
            icon: "questionmark.circle.fill",
            color: AirLinkColors.textSecondary
        ) {
            VStack(spacing: AppTheme.current.spacing.md) {
                FAQItem(
                    question: "Czy mogę używać AirLink bez internetu?",
                    answer: "Tak! AirLink został zaprojektowany właśnie do komunikacji bez internetu. Potrzebujesz tylko innych urządzeń z AirLink w pobliżu."
                )
                
                FAQItem(
                    question: "Jak daleko mogę być od innych użytkowników?",
                    answer: "Zasięg Bluetooth to około 30-100 metrów, ale dzięki mesh network zasięg może być znacznie większy jeśli są inne urządzenia pomiędzy."
                )
                
                FAQItem(
                    question: "Czy wiadomości są naprawdę bezpieczne?",
                    answer: "Tak, używamy tego samego szyfrowania co aplikacje jak Signal czy WhatsApp, ale bez konieczności przesyłania przez internet."
                )
                
                FAQItem(
                    question: "Co się dzieje z moimi danymi gdy usunę aplikację?",
                    answer: "Wszystkie dane zostaną całkowicie usunięte z urządzenia. Nie ma kopii zapasowych ani serwerów które przechowują Twoje dane."
                )
                
                FAQItem(
                    question: "Czy mogę używać AirLink w samolotach?",
                    answer: "Tak! Dzięki trybowi offline możesz komunikować się z innymi pasażerami nawet podczas lotu (jeśli Bluetooth jest dozwolony)."
                )
            }
        }
    }
}

// MARK: - Info Section

private struct InfoSection<Content: View>: View {
    
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                Image(systemName: icon)
                    .font(.title3.weight(.medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.current.typography.title3)
                    .foregroundColor(AirLinkColors.textPrimary)
            }
            
            content
        }
        .padding(AppTheme.current.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
}

// MARK: - Principle Card

private struct PrincipleCard: View {
    
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AirLinkColors.statusSuccess)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.current.typography.headline)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text(description)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusSmall)
                .fill(AirLinkColors.statusSuccess.opacity(0.1))
        )
    }
}

// MARK: - How It Works Step

private struct HowItWorksStep: View {
    
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.md) {
            ZStack {
                Circle()
                    .fill(AirLinkColors.primary)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.current.typography.headline)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text(description)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Data Handling Row

private struct DataHandlingRow: View {
    
    let category: String
    let handling: String
    let retention: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category)
                .font(AppTheme.current.typography.headline)
                .foregroundColor(AirLinkColors.textPrimary)
            
            Text("Obsługa: \(handling)")
                .font(AppTheme.current.typography.body)
                .foregroundColor(AirLinkColors.textSecondary)
            
            Text("Przechowywanie: \(retention)")
                .font(AppTheme.current.typography.caption)
                .foregroundColor(AirLinkColors.textTertiary)
        }
        .padding(.vertical, AppTheme.current.spacing.xs)
    }
}

// MARK: - Security Feature

private struct SecurityFeature: View {
    
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AirLinkColors.statusError)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.current.typography.headline)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Text(description)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    
    let permission: String
    let reason: String
    let required: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: required ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(required ? AirLinkColors.statusSuccess : AirLinkColors.textTertiary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission)
                        .font(AppTheme.current.typography.headline)
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    if required {
                        Text("Wymagane")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AirLinkColors.statusError)
                            )
                    }
                }
                
                Text(reason)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - FAQ Item

private struct FAQItem: View {
    
    let question: String
    let answer: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.sm) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(question)
                        .font(AppTheme.current.typography.headline)
                        .foregroundColor(AirLinkColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(AirLinkColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.current.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusSmall)
                .fill(AirLinkColors.backgroundTertiary)
        )
    }
}

// MARK: - Preview

#Preview {
    PrivacyInfo()
        .withAppTheme()
}
