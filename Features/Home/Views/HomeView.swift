//
//  HomeView.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - HomeView

/// Główny ekran aplikacji AirLink z listą czatów
struct HomeView: View {
    
    // MARK: - Environment
    
    @Environment(ChatService.self) private var chatService
    @Environment(ContactService.self) private var contactService
    @Environment(ConnectivityService.self) private var connectivityService
    @Environment(NavigationCoordinator.self) private var coordinator
    
    // MARK: - State
    
    @State private var viewModel: HomeViewModel?
    @State private var searchText = ""
    @State private var selectedFilter: ChatFilter = .all
    @State private var isSearchActive = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $coordinator.homeNavigationPath) {
            ZStack {
                // Background
                AirLinkColors.background
                    .ignoresSafeArea()
                
                // Main content
                mainContent
                
                // FAB
                fabButton
            }
            .navigationTitle("AirLink")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    connectivityStatusView
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearchActive,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Szukaj czatów..."
            )
            .onSubmit(of: .search) {
                viewModel?.searchText = searchText
            }
            .onChange(of: searchText) { _, newValue in
                viewModel?.searchText = newValue
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $coordinator.isShowingNewChatSheet) {
                NewChatSheet()
            }
            .sheet(isPresented: $coordinator.isShowingQRScanner) {
                QRScannerView()
            }
            .sheet(isPresented: $coordinator.isShowingQRDisplay) {
                QRDisplayView()
            }
        }
        .onAppear {
            setupViewModel()
            viewModel?.onAppear()
        }
        .onDisappear {
            viewModel?.onDisappear()
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if let viewModel = viewModel {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.shouldShowEmptyState {
                emptyStateView
            } else if viewModel.shouldShowSearchEmptyState {
                searchEmptyStateView
            } else {
                chatListView
            }
        } else {
            loadingView
        }
    }
    
    // MARK: - Chat List
    
    private var chatListView: some View {
        VStack(spacing: 0) {
            // Filter bar
            if !isSearchActive {
                filterBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            // Chat list
            List {
                ForEach(viewModel?.displayedChats ?? []) { chat in
                    ChatRowView(
                        chat: chat,
                        onTap: { viewModel?.openChat(chat) },
                        onDelete: { viewModel?.deleteChat(chat) },
                        onToggleRead: { viewModel?.toggleReadStatus(chat) },
                        onToggleMute: { viewModel?.toggleMuteStatus(chat) }
                    )
                    .listRowBackground(AirLinkColors.listRowBackground)
                    .listRowSeparator(.visible, edges: .bottom)
                    .listRowSeparatorTint(AirLinkColors.listSeparator)
                }
                .onDelete(perform: deleteChats)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChatFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(filter)
                    ) {
                        selectedFilter = filter
                        viewModel?.setFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            LoadingView.standard(message: "Ładowanie czatów...")
            
            // Skeleton placeholders
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    ChatRowSkeleton()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView.noChats {
            viewModel?.handleFABTap()
        }
        .padding()
    }
    
    // MARK: - Search Empty State
    
    private var searchEmptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AirLinkColors.textTertiary)
            
            Text("Brak wyników")
                .title3Style()
            
            if selectedFilter != .all {
                Text("Nie znaleziono czatów dla filtru '\(selectedFilter.title)'")
                    .bodyStyle()
                    .multilineTextAlignment(.center)
                
                Button("Wyczyść filtry") {
                    selectedFilter = .all
                    searchText = ""
                    viewModel?.resetFilters()
                }
                .primaryStyle()
            } else {
                Text("Spróbuj użyć innych słów kluczowych")
                    .bodyStyle()
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    // MARK: - FAB Button
    
    private var fabButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                FloatingActionButton.primary(
                    icon: AppConstants.Icons.add,
                    isVisible: viewModel?.shouldShowFAB ?? true
                ) {
                    viewModel?.handleFABTap()
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100) // Above tab bar
            }
        }
    }
    
    // MARK: - Connectivity Status
    
    private var connectivityStatusView: some View {
        HStack(spacing: 6) {
            // Signal strength indicator
            SignalIndicator.compact(
                strength: getAverageSignalStrength(),
                isMesh: hasMeshConnections()
            )
            
            // Connection count
            Text("\(viewModel?.onlineContactsCount ?? 0)")
                .font(AppTheme.current.typography.caption)
                .foregroundColor(AirLinkColors.textSecondary)
        }
        .onTapGesture {
            coordinator.switchToTab(.contacts)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        guard viewModel == nil else { return }
        
        viewModel = HomeViewModel(
            chatService: chatService,
            contactService: contactService,
            connectivityService: connectivityService,
            coordinator: coordinator
        )
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            viewModel?.refreshChats()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                continuation.resume()
            }
        }
    }
    
    private func deleteChats(at offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        
        for index in offsets {
            let chat = viewModel.displayedChats[index]
            viewModel.deleteChat(chat)
        }
    }
    
    private func getFilterCount(_ filter: ChatFilter) -> Int {
        guard let viewModel = viewModel else { return 0 }
        
        switch filter {
        case .all:
            return viewModel.allChats.count
        case .unread:
            return viewModel.allChats.filter { $0.unreadCount > 0 }.count
        case .groups:
            return viewModel.allChats.filter { $0.isGroup }.count
        case .direct:
            return viewModel.allChats.filter { $0.isDirectMessage }.count
        case .active:
            return viewModel.allChats.filter { $0.isActive }.count
        }
    }
    
    private func getAverageSignalStrength() -> Int {
        let onlineContacts = contactService.onlineContacts
        guard !onlineContacts.isEmpty else { return 0 }
        
        let totalStrength = onlineContacts.reduce(0) { $0 + $1.signalStrength }
        return totalStrength / onlineContacts.count
    }
    
    private func hasMeshConnections() -> Bool {
        return contactService.onlineContacts.contains { $0.isConnectedViaMesh }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let filter: ChatFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption.weight(.medium))
                
                Text(filter.title)
                    .font(AppTheme.current.typography.buttonSmall)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(isSelected ? AirLinkColors.textOnPrimary : AirLinkColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? AirLinkColors.primaryOpacity20 : AirLinkColors.backgroundSecondary)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AirLinkColors.primary : AirLinkColors.backgroundSecondary)
            )
            .foregroundColor(isSelected ? AirLinkColors.textOnPrimary : AirLinkColors.textPrimary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chat Row View

private struct ChatRowView: View {
    let chat: Chat
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggleRead: () -> Void
    let onToggleMute: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                avatarView
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title and time
                    HStack {
                        Text(chat.displayName)
                            .chatTitleStyle()
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let lastMessageDate = chat.lastMessageDate {
                            Text(formatTime(lastMessageDate))
                                .messageTimestampStyle()
                        }
                    }
                    
                    // Subtitle and indicators
                    HStack {
                        Text(chat.lastMessageDisplay)
                            .chatSubtitleStyle()
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Indicators
                        indicatorsView
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems
        }
    }
    
    private var avatarView: some View {
        Group {
            if chat.isGroup {
                // Group avatar
                ZStack {
                    Circle()
                        .fill(AirLinkColors.avatarGradient(for: chat.displayName))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            } else if let participant = chat.participants.first {
                // Contact avatar
                AvatarView.contact(
                    participant,
                    size: .medium,
                    showStatus: true
                )
            } else {
                // Fallback avatar
                Circle()
                    .fill(AirLinkColors.backgroundSecondary)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(AirLinkColors.textTertiary)
                    )
            }
        }
    }
    
    private var indicatorsView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Unread badge
            if chat.unreadCount > 0 {
                Text("\(min(chat.unreadCount, 99))\(chat.unreadCount > 99 ? "+" : "")")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(AirLinkColors.primary)
                    .clipShape(Circle())
            }
            
            // Status indicators
            HStack(spacing: 4) {
                // Mute indicator
                if chat.isMuted {
                    Image(systemName: "bell.slash.fill")
                        .font(.caption2)
                        .foregroundColor(AirLinkColors.textTertiary)
                }
                
                // Active indicator
                if chat.isActive {
                    Circle()
                        .fill(AirLinkColors.statusOnline)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            onToggleRead()
        } label: {
            Label(
                chat.unreadCount > 0 ? "Oznacz jako przeczytane" : "Oznacz jako nieprzeczytane",
                systemImage: chat.unreadCount > 0 ? "envelope.open" : "envelope.badge"
            )
        }
        
        Button {
            onToggleMute()
        } label: {
            Label(
                chat.isMuted ? "Wyłącz wyciszenie" : "Wycisz",
                systemImage: chat.isMuted ? "bell" : "bell.slash"
            )
        }
        
        Divider()
        
        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("Usuń czat", systemImage: "trash")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Chat Row Skeleton

private struct ChatRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Avatar skeleton
            Circle()
                .fill(AirLinkColors.backgroundSecondary)
                .frame(width: 50, height: 50)
                .shimmer()
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AirLinkColors.backgroundSecondary)
                        .frame(width: 120, height: 16)
                        .shimmer()
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AirLinkColors.backgroundSecondary)
                        .frame(width: 40, height: 12)
                        .shimmer()
                }
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(AirLinkColors.backgroundSecondary)
                    .frame(width: 200, height: 14)
                    .shimmer()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - New Chat Sheet

private struct NewChatSheet: View {
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(ContactService.self) private var contactService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nowy czat")
                    .title2Style()
                    .padding(.top)
                
                if contactService.contacts.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "Brak kontaktów",
                        description: "Dodaj kontakty żeby rozpocząć rozmowy",
                        actionTitle: "Skanuj kod QR",
                        actionIcon: "qrcode.viewfinder"
                    ) {
                        coordinator.hideNewChatSheet()
                        coordinator.showQRScanner()
                    }
                } else {
                    // Lista kontaktów do wyboru
                    List(contactService.contacts) { contact in
                        ContactRowForSelection(contact: contact) {
                            // TODO: Create chat with contact
                            coordinator.hideNewChatSheet()
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        coordinator.hideNewChatSheet()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Nowa grupa") {
                        coordinator.hideNewChatSheet()
                        coordinator.showGroupCreation()
                    }
                    .disabled(contactService.contacts.count < 2)
                }
            }
        }
    }
}

// MARK: - Contact Row for Selection

private struct ContactRowForSelection: View {
    let contact: Contact
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AvatarView.contact(contact, size: .medium)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.nickname)
                        .contactNameStyle()
                    
                    Text(contact.connectionStatus)
                        .contactStatusStyle()
                }
                
                Spacer()
                
                if contact.isOnline {
                    SignalIndicator.compact(
                        strength: contact.signalStrength,
                        isMesh: contact.isConnectedViaMesh
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .withAppTheme()
}
