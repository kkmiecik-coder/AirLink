//
//  TabItem.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - TabItem

/// Enum reprezentujący zakładki w głównym tab barze AirLink
enum TabItem: String, CaseIterable, Identifiable {
    case home = "home"
    case contacts = "contacts"
    case settings = "settings"
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    /// Lokalizowana nazwa zakładki
    var title: String {
        switch self {
        case .home:
            return String(localized: "tab.home.title", defaultValue: "Główna")
        case .contacts:
            return String(localized: "tab.contacts.title", defaultValue: "Kontakty")
        case .settings:
            return String(localized: "tab.settings.title", defaultValue: "Ustawienia")
        }
    }
    
    /// Ikona zakładki (SF Symbol)
    var icon: String {
        switch self {
        case .home:
            return AppConstants.Icons.homeTab
        case .contacts:
            return AppConstants.Icons.contactsTab
        case .settings:
            return AppConstants.Icons.settingsTab
        }
    }
    
    /// Ikona wypełniona (selected state)
    var filledIcon: String {
        switch self {
        case .home:
            return AppConstants.Icons.homeTab + ".fill"
        case .contacts:
            return AppConstants.Icons.contactsTab + ".fill"
        case .settings:
            return AppConstants.Icons.settingsTab + ".fill"
        }
    }
    
    /// Opis dostępności dla VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .home:
            return String(localized: "tab.home.accessibility", defaultValue: "Główna zakładka z listą rozmów")
        case .contacts:
            return String(localized: "tab.contacts.accessibility", defaultValue: "Zakładka kontaktów")
        case .settings:
            return String(localized: "tab.settings.accessibility", defaultValue: "Zakładka ustawień aplikacji")
        }
    }
    
    /// Hint dostępności
    var accessibilityHint: String {
        switch self {
        case .home:
            return String(localized: "tab.home.hint", defaultValue: "Przejdź do listy aktywnych rozmów")
        case .contacts:
            return String(localized: "tab.contacts.hint", defaultValue: "Zobacz i zarządzaj swoimi kontaktami")
        case .settings:
            return String(localized: "tab.settings.hint", defaultValue: "Otwórz ustawienia aplikacji")
        }
    }
    
    // MARK: - Badge Support
    
    /// Czy zakładka może wyświetlać badge
    var supportsBadge: Bool {
        switch self {
        case .home, .contacts:
            return true
        case .settings:
            return false
        }
    }
    
    /// Maksymalna wartość badge (99+ dla większych liczb)
    var maxBadgeValue: Int {
        return 99
    }
    
    // MARK: - Navigation Properties
    
    /// Czy zakładka wymaga specjalnych uprawnień
    var requiresPermissions: Bool {
        switch self {
        case .contacts:
            return true // Może wymagać Bluetooth
        case .home, .settings:
            return false
        }
    }
    
    /// Domyślna akcja po wybraniu zakładki
    var defaultAction: TabAction {
        switch self {
        case .home:
            return .showRecentChats
        case .contacts:
            return .showContactsList
        case .settings:
            return .showMainSettings
        }
    }
}

// MARK: - Tab Actions

/// Akcje wykonywane po wybraniu zakładki
enum TabAction {
    case showRecentChats
    case showContactsList
    case showMainSettings
    case showQRScanner
    case showNewChat
    
    var analyticsEvent: String {
        switch self {
        case .showRecentChats:
            return "tab_home_opened"
        case .showContactsList:
            return "tab_contacts_opened"
        case .showMainSettings:
            return "tab_settings_opened"
        case .showQRScanner:
            return "qr_scanner_opened"
        case .showNewChat:
            return "new_chat_started"
        }
    }
}

// MARK: - Tab Item View Helpers

extension TabItem {
    
    /// Tworzy widok ikony dla zakładki
    @ViewBuilder
    func iconView(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? filledIcon : icon)
            .symbolVariant(isSelected ? .fill : .none)
            .font(AppTheme.current.typography.tabTitle)
            .foregroundColor(isSelected ? AirLinkColors.tabBarSelected : AirLinkColors.tabBarUnselected)
            .animation(AppTheme.current.animations.fast, value: isSelected)
    }
    
    /// Tworzy widok tekstu dla zakładki
    @ViewBuilder
    func titleView(isSelected: Bool) -> some View {
        Text(title)
            .font(AppTheme.current.typography.tabTitle)
            .foregroundColor(isSelected ? AirLinkColors.tabBarSelected : AirLinkColors.tabBarUnselected)
            .animation(AppTheme.current.animations.fast, value: isSelected)
    }
    
    /// Tworzy kompletny widok zakładki
    @ViewBuilder
    func tabItemView(isSelected: Bool, badgeCount: Int = 0) -> some View {
        VStack(spacing: 4) {
            ZStack {
                iconView(isSelected: isSelected)
                
                // Badge
                if supportsBadge && badgeCount > 0 {
                    Text("\(min(badgeCount, maxBadgeValue))\(badgeCount > maxBadgeValue ? "+" : "")")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(AirLinkColors.statusError)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
            
            titleView(isSelected: isSelected)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Tab Item Extensions

extension TabItem {
    
    /// Sprawdza czy zakładka jest dostępna (np. na podstawie uprawnień)
    func isAvailable() -> Bool {
        switch self {
        case .home, .settings:
            return true
        case .contacts:
            // Sprawdź czy Bluetooth jest dostępny
            return true // Placeholder - implementacja z ConnectivityService
        }
    }
    
    /// Zwraca wymaganą akcję przed pokazaniem zakładki
    func requiredAction() -> TabPreAction? {
        switch self {
        case .contacts:
            return .checkBluetoothPermission
        case .home, .settings:
            return nil
        }
    }
}

// MARK: - Tab Pre-Actions

/// Akcje wymagane przed pokazaniem zakładki
enum TabPreAction {
    case checkBluetoothPermission
    case checkCameraPermission
    case checkPhotoLibraryPermission
    
    var permissionType: String {
        switch self {
        case .checkBluetoothPermission:
            return "bluetooth"
        case .checkCameraPermission:
            return "camera"
        case .checkPhotoLibraryPermission:
            return "photo_library"
        }
    }
}

// MARK: - Tab Item State

/// Stan zakładki z dodatkowymi informacjami
struct TabItemState {
    let item: TabItem
    let isSelected: Bool
    let badgeCount: Int
    let isEnabled: Bool
    let requiresAttention: Bool // Np. dla ważnych powiadomień
    
    init(item: TabItem, isSelected: Bool = false, badgeCount: Int = 0, isEnabled: Bool = true, requiresAttention: Bool = false) {
        self.item = item
        self.isSelected = isSelected
        self.badgeCount = badgeCount
        self.isEnabled = isEnabled
        self.requiresAttention = requiresAttention
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension TabItem {
    
    /// Przykładowe stany zakładek dla preview
    static let previewStates: [TabItemState] = [
        TabItemState(item: .home, isSelected: true, badgeCount: 3),
        TabItemState(item: .contacts, badgeCount: 2),
        TabItemState(item: .settings)
    ]
}
#endif

// MARK: - Preview

#Preview("Tab Items") {
    VStack(spacing: 20) {
        Text("Tab Items Preview")
            .headlineStyle()
        
        HStack(spacing: 40) {
            ForEach(TabItem.allCases) { tab in
                VStack(spacing: 16) {
                    // Selected state
                    tab.tabItemView(isSelected: true, badgeCount: tab == .home ? 5 : (tab == .contacts ? 2 : 0))
                    
                    Text("Selected")
                        .caption2Style()
                    
                    Divider()
                    
                    // Normal state
                    tab.tabItemView(isSelected: false, badgeCount: tab == .home ? 5 : (tab == .contacts ? 2 : 0))
                    
                    Text("Normal")
                        .caption2Style()
                }
            }
        }
    }
    .padding()
    .background(AirLinkColors.background)
}
