//
//  StorageInfo.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - StorageInfo

/// Widok informacji o wykorzystaniu pamięci przez AirLink
/// Pokazuje statystyki, zarządzanie miejscem i opcje czyszczenia
struct StorageInfo: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var viewModel
    
    // MARK: - State
    
    @State private var showingCleanupConfirmation = false
    @State private var selectedCleanupOptions: Set<CleanupOption> = []
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.current.spacing.xl) {
                    
                    // Storage overview
                    storageOverviewSection
                    
                    // Usage breakdown
                    usageBreakdownSection
                    
                    // Cleanup options
                    cleanupOptionsSection
                    
                    // Storage tips
                    storageTipsSection
                }
                .padding(.horizontal, AppTheme.current.spacing.lg)
                .padding(.top, AppTheme.current.spacing.lg)
                .padding(.bottom, AppTheme.current.spacing.xxl)
            }
            .navigationTitle("Pamięć")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refreshStorageStats()
        }
        .confirmationDialog(
            "Wyczyść dane",
            isPresented: $showingCleanupConfirmation
        ) {
            Button("Wyczyść wybrane dane", role: .destructive) {
                performCleanup()
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Ta operacja jest nieodwracalna. Wybrane dane zostaną trwale usunięte.")
        }
    }
    
    // MARK: - Storage Overview Section
    
    private var storageOverviewSection: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            // Main storage indicator
            storageIndicator
            
            // Quick stats
            quickStatsGrid
        }
        .padding(AppTheme.current.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Storage Indicator
    
    private var storageIndicator: some View {
        VStack(spacing: AppTheme.current.spacing.md) {
            // Usage circle
            ZStack {
                Circle()
                    .stroke(AirLinkColors.backgroundTertiary, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: viewModel.storageUsagePercentage)
                    .stroke(
                        storageUsageColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(AppTheme.current.animations.medium, value: viewModel.storageUsagePercentage)
                
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.storageUsagePercentage * 100))%")
                        .font(.title.weight(.bold))
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    Text("używane")
                        .font(.caption)
                        .foregroundColor(AirLinkColors.textSecondary)
                }
            }
            
            // Storage amounts
            VStack(spacing: 4) {
                Text(viewModel.formatStorageSize(viewModel.storageStats.usedSpace))
                    .font(AppTheme.current.typography.title3)
                    .foregroundColor(AirLinkColors.textPrimary)
                    .fontWeight(.semibold)
                
                Text("z \(viewModel.formatStorageSize(viewModel.storageStats.totalSpace)) dostępne")
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
            }
            
            // Recommendation
            if viewModel.isCleanupRecommended {
                HStack(spacing: AppTheme.current.spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(AirLinkColors.statusWarning)
                    
                    Text(viewModel.storageRecommendation)
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(AirLinkColors.statusWarning)
                }
                .padding(.horizontal, AppTheme.current.spacing.sm)
                .padding(.vertical, AppTheme.current.spacing.xs)
                .background(
                    Capsule()
                        .fill(AirLinkColors.statusWarning.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppTheme.current.spacing.sm) {
            StatCard(
                title: "Wiadomości",
                value: "\(viewModel.storageStats.totalMessages)",
                icon: "message.badge",
                color: AirLinkColors.primary
            )
            
            StatCard(
                title: "Załączniki",
                value: "\(viewModel.storageStats.totalAttachments)",
                icon: "paperclip",
                color: AirLinkColors.statusWarning
            )
            
            StatCard(
                title: "Czaty",
                value: "\(viewModel.storageStats.totalChats)",
                icon: "bubble.left.and.bubble.right",
                color: AirLinkColors.statusSuccess
            )
            
            StatCard(
                title: "Kontakty",
                value: "\(viewModel.storageStats.totalContacts)",
                icon: "person.2",
                color: AirLinkColors.statusMesh
            )
        }
    }
    
    // MARK: - Usage Breakdown Section
    
    private var usageBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Podział wykorzystania")
                .font(AppTheme.current.typography.title3)
                .foregroundColor(AirLinkColors.textPrimary)
            
            VStack(spacing: AppTheme.current.spacing.sm) {
                UsageRow(
                    category: "Wiadomości tekstowe",
                    size: viewModel.storageStats.messagesSize,
                    percentage: Double(viewModel.storageStats.messagesSize) / Double(viewModel.storageStats.usedSpace),
                    color: AirLinkColors.primary
                )
                
                UsageRow(
                    category: "Zdjęcia i multimedia",
                    size: viewModel.storageStats.attachmentsSize,
                    percentage: Double(viewModel.storageStats.attachmentsSize) / Double(viewModel.storageStats.usedSpace),
                    color: AirLinkColors.statusWarning
                )
                
                UsageRow(
                    category: "Dane kontaktów",
                    size: viewModel.storageStats.contactsSize,
                    percentage: Double(viewModel.storageStats.contactsSize) / Double(viewModel.storageStats.usedSpace),
                    color: AirLinkColors.statusSuccess
                )
                
                UsageRow(
                    category: "Cache i dane tymczasowe",
                    size: viewModel.storageStats.cacheSize,
                    percentage: Double(viewModel.storageStats.cacheSize) / Double(viewModel.storageStats.usedSpace),
                    color: AirLinkColors.textTertiary
                )
            }
        }
        .padding(AppTheme.current.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Cleanup Options Section
    
    private var cleanupOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Opcje czyszczenia")
                .font(AppTheme.current.typography.title3)
                .foregroundColor(AirLinkColors.textPrimary)
            
            VStack(spacing: 0) {
                CleanupOptionRow(
                    option: .cache,
                    isSelected: selectedCleanupOptions.contains(.cache),
                    onToggle: { toggleCleanupOption(.cache) }
                )
                
                Divider()
                    .padding(.leading, 44)
                
                CleanupOptionRow(
                    option: .oldMessages,
                    isSelected: selectedCleanupOptions.contains(.oldMessages),
                    onToggle: { toggleCleanupOption(.oldMessages) }
                )
                
                Divider()
                    .padding(.leading, 44)
                
                CleanupOptionRow(
                    option: .oldAttachments,
                    isSelected: selectedCleanupOptions.contains(.oldAttachments),
                    onToggle: { toggleCleanupOption(.oldAttachments) }
                )
                
                Divider()
                    .padding(.leading, 44)
                
                CleanupOptionRow(
                    option: .orphanedData,
                    isSelected: selectedCleanupOptions.contains(.orphanedData),
                    onToggle: { toggleCleanupOption(.orphanedData) }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                    .fill(AirLinkColors.backgroundTertiary)
            )
            
            // Cleanup button
            if !selectedCleanupOptions.isEmpty {
                Button(action: { showingCleanupConfirmation = true }) {
                    HStack {
                        if viewModel.isCleanupInProgress {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "trash")
                        }
                        
                        Text(viewModel.isCleanupInProgress ? "Czyszczenie..." : "Wyczyść wybrane")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                            .fill(AirLinkColors.statusError)
                    )
                }
                .disabled(viewModel.isCleanupInProgress)
                
                if viewModel.isCleanupInProgress && viewModel.cleanupProgress > 0 {
                    ProgressView(value: viewModel.cleanupProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: AirLinkColors.statusError))
                }
            }
        }
        .padding(AppTheme.current.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Storage Tips Section
    
    private var storageTipsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.current.spacing.md) {
            Text("Wskazówki")
                .font(AppTheme.current.typography.title3)
                .foregroundColor(AirLinkColors.textPrimary)
            
            VStack(spacing: AppTheme.current.spacing.sm) {
                StorageTip(
                    icon: "photo.stack",
                    title: "Kompresja zdjęć",
                    description: "Zdjęcia są automatycznie kompresowane przed wysłaniem, żeby zaoszczędzić miejsce"
                )
                
                StorageTip(
                    icon: "clock.arrow.circlepath",
                    title: "Automatyczne czyszczenie",
                    description: "Stare dane cache są automatycznie usuwane po 7 dniach"
                )
                
                StorageTip(
                    icon: "externaldrive.badge.minus",
                    title: "Zarządzanie miejscem",
                    description: "Usuwaj stare czaty i załączniki których już nie potrzebujesz"
                )
                
                StorageTip(
                    icon: "icloud.slash",
                    title: "Lokalne przechowywanie",
                    description: "Wszystkie dane są przechowywane tylko na Twoim urządzeniu - nie ma synchronizacji z chmurą"
                )
            }
        }
        .padding(AppTheme.current.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusMedium)
                .fill(AirLinkColors.backgroundSecondary)
        )
    }
    
    // MARK: - Computed Properties
    
    private var storageUsageColor: Color {
        if viewModel.storageUsagePercentage > 0.9 {
            return AirLinkColors.statusError
        } else if viewModel.storageUsagePercentage > 0.75 {
            return AirLinkColors.statusWarning
        } else {
            return AirLinkColors.statusSuccess
        }
    }
    
    // MARK: - Actions
    
    private func toggleCleanupOption(_ option: CleanupOption) {
        if selectedCleanupOptions.contains(option) {
            selectedCleanupOptions.remove(option)
        } else {
            selectedCleanupOptions.insert(option)
        }
    }
    
    private func performCleanup() {
        Task {
            await viewModel.performCleanup(options: selectedCleanupOptions)
            selectedCleanupOptions.removeAll()
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.current.spacing.xs) {
            HStack(spacing: AppTheme.current.spacing.xs) {
                Image(systemName: icon)
                    .font(.caption.weight(.medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.current.typography.caption)
                    .foregroundColor(AirLinkColors.textSecondary)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(AppTheme.current.typography.headline)
                    .foregroundColor(AirLinkColors.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
            }
        }
        .padding(AppTheme.current.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusSmall)
                .fill(AirLinkColors.backgroundTertiary)
        )
    }
}

// MARK: - Usage Row

private struct UsageRow: View {
    
    let category: String
    let size: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.current.spacing.xs) {
            HStack {
                Text(category)
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textPrimary)
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                    .font(AppTheme.current.typography.body)
                    .foregroundColor(AirLinkColors.textSecondary)
                    .fontWeight(.medium)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AirLinkColors.backgroundTertiary)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                        .cornerRadius(2)
                        .animation(AppTheme.current.animations.medium, value: percentage)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Cleanup Option Row

private struct CleanupOptionRow: View {
    
    let option: CleanupOption
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? AirLinkColors.primary : AirLinkColors.textTertiary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(AppTheme.current.typography.body)
                        .foregroundColor(AirLinkColors.textPrimary)
                    
                    Text(option.description)
                        .font(AppTheme.current.typography.caption)
                        .foregroundColor(AirLinkColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Text(option.estimatedSpace)
                    .font(AppTheme.current.typography.caption)
                    .foregroundColor(AirLinkColors.textTertiary)
            }
            .padding(AppTheme.current.spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Storage Tip

private struct StorageTip: View {
    
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.current.spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AirLinkColors.primary)
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
        .padding(AppTheme.current.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.current.layout.cornerRadiusSmall)
                .fill(AirLinkColors.backgroundTertiary)
        )
    }
}

// MARK: - Cleanup Option

enum CleanupOption: String, CaseIterable {
    case cache = "cache"
    case oldMessages = "oldMessages"
    case oldAttachments = "oldAttachments"
    case orphanedData = "orphanedData"
    
    var title: String {
        switch self {
        case .cache:
            return "Cache i pliki tymczasowe"
        case .oldMessages:
            return "Stare wiadomości (>30 dni)"
        case .oldAttachments:
            return "Stare załączniki (>30 dni)"
        case .orphanedData:
            return "Uszkodzone dane"
        }
    }
    
    var description: String {
        switch self {
        case .cache:
            return "Pliki cache, miniatury i dane tymczasowe"
        case .oldMessages:
            return "Wiadomości starsze niż 30 dni"
        case .oldAttachments:
            return "Zdjęcia i załączniki starsze niż 30 dni"
        case .orphanedData:
            return "Porzucone pliki bez powiązanych wiadomości"
        }
    }
    
    var estimatedSpace: String {
        switch self {
        case .cache:
            return "~50 MB"
        case .oldMessages:
            return "~20 MB"
        case .oldAttachments:
            return "~150 MB"
        case .orphanedData:
            return "~10 MB"
        }
    }
}

// MARK: - Extensions

extension SettingsViewModel {
    
    /// Odświeża statystyki storage
    func refreshStorageStats() async {
        // Implementacja odświeżania statystyk
        await MainActor.run {
            // Update storage stats
        }
    }
    
    /// Wykonuje cleanup wybranych opcji
    func performCleanup(options: Set<CleanupOption>) async {
        await MainActor.run {
            isCleanupInProgress = true
            cleanupProgress = 0.0
        }
        
        // Simulate cleanup process
        for (index, option) in options.enumerated() {
            await MainActor.run {
                cleanupProgress = Double(index + 1) / Double(options.count)
            }
            
            // Simulate cleanup time
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        await MainActor.run {
            isCleanupInProgress = false
            cleanupProgress = 0.0
            // Update storage stats after cleanup
        }
    }
}

// MARK: - Preview

#Preview {
    StorageInfo()
        .withAppTheme()
        .environment(SettingsViewModel.createMockViewModel())
}

#Preview("High Usage") {
    let viewModel = SettingsViewModel.createMockViewModel()
    viewModel.simulateState(.lowStorage)
    
    return StorageInfo()
        .withAppTheme()
        .environment(viewModel)
}
