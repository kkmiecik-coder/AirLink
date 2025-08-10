//
//  MainTabView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - MainTabView

/// Główny tab bar aplikacji AirLink
/// Obsługuje 3 zakładki: Home, Contacts, Settings
struct MainTabView: View {
    
    // MARK: - State
    
    @State private var selectedTab: TabItem = .home
    @State private var coordinator = NavigationCoordinator()
    
    // MARK: - Services (będą wstrzykiwane przez DI)
    
    @State private var contactService = ContactService.createMockService()
    @State private var connectivityService = ConnectivityService()
    @State private var chatService = ChatService.createMockService()
    @State private var qrService = QRService.createMockService()
    @State private var mediaService = MediaService.createMockService()
    @State private var storageService = StorageService.createMockService()
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == .home ? AppConstants.Icons.homeTab + ".fill" : AppConstants.Icons.homeTab)
                        .environment(\.symbolVariants, selectedTab == .home ? .fill : .none)
                    Text("Główna")
                }
                .tag(TabItem.home)
            
            // MARK: - Contacts Tab
            ContactsView()
                .tabItem {
                    Image(systemName: selectedTab == .contacts ? AppConstants.Icons.contactsTab + ".fill" : AppConstants.Icons.contactsTab)
                        .environment(\.symbolVariants, selectedTab == .contacts ? .fill : .none)
                    Text("Kontakty")
                }
                .tag(TabItem.contacts)
            
            // MARK: - Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == .settings ? AppConstants.Icons.settingsTab + ".fill" : AppConstants.Icons.settingsTab)
                        .environment(\.symbolVariants, selectedTab == .settings ? .fill : .none)
                    Text("Ustawienia")
                }
                .tag(TabItem.settings)
        }
        .tint(AirLinkColors.primary)
        .environment(coordinator)
        .environment(contactService)
        .environment(connectivityService)
        .environment(chatService)
        .environment(qrService)
        .environment(mediaService)
        .environment(storageService)
        .onAppear {
            setupTabBarAppearance()
            startServices()
        }
        .onDisappear {
            stopServices()
        }
    }
    
    // MARK: - Private Methods
    
    /// Konfiguruje wygląd tab bara
    private func setupTabBarAppearance() {
        // Podstawowe ustawienia tab bara
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        // Kolory
        tabBarAppearance.backgroundColor = UIColor(AirLinkColors.tabBarBackground)
        tabBarAppearance.selectionIndicatorTint = UIColor(AirLinkColors.tabBarSelected)
        
        // Kolory ikon i tekstu
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(AirLinkColors.tabBarUnselected)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AirLinkColors.tabBarUnselected),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(AirLinkColors.tabBarSelected)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AirLinkColors.tabBarSelected),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Zastosuj appearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    /// Uruchamia wszystkie serwisy
    private func startServices() {
        connectivityService.start()
        contactService.start()
        chatService.start()
        
        print("🚀 All services started")
    }
    
    /// Zatrzymuje wszystkie serwisy
    private func stopServices() {
        connectivityService.stop()
        contactService.stop()
        chatService.stop()
        
        print("🛑 All services stopped")
    }
}

// MARK: - Tab Badge Support

extension MainTabView {
    
    /// Oblicza badge dla zakładki Home (nieprzeczytane wiadomości)
    private var homeBadgeCount: Int {
        chatService.getTotalUnreadCount()
    }
    
    /// Oblicza badge dla zakładki Contacts (nowe kontakty online)
    private var contactsBadgeCount: Int {
        contactService.onlineContacts.count
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .withAppTheme()
}
