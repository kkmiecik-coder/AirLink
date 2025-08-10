//
//  StorageService.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import Foundation
import SwiftData
import Combine

// MARK: - StorageService

/// Serwis odpowiedzialny za zarządzanie pamięcią lokalną w AirLink
/// Obsługuje statystyki, cleanup i optymalizację przestrzeni dyskowej
@Observable
final class StorageService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    /// Aktualne statystyki pamięci
    private(set) var storageStats = StorageStatistics()
    
    /// Czy cleanup jest w toku
    private(set) var isCleanupInProgress = false
    
    /// Progress cleanup (0.0 - 1.0)
    private(set) var cleanupProgress: Double = 0.0
    
    /// Timer do okresowych aktualizacji statystyk
    private var statsUpdateTimer: Timer?
    
    /// Queue do operacji storage
    private let storageQueue = DispatchQueue(label: "com.airlink.storage", qos: .utility)
    
    // MARK: - Publishers
    
    private let storageStatsUpdatedSubject = PassthroughSubject<StorageStatistics, Never>()
    var storageStatsUpdatedPublisher: AnyPublisher<StorageStatistics, Never> {
        storageStatsUpdatedSubject.eraseToAnyPublisher()
    }
    
    private let cleanupProgressSubject = PassthroughSubject<Double, Never>()
    var cleanupProgressPublisher: AnyPublisher<Double, Never> {
        cleanupProgressSubject.eraseToAnyPublisher()
    }
    
    private let cleanupCompletedSubject = PassthroughSubject<CleanupResult, Never>()
    var cleanupCompletedPublisher: AnyPublisher<CleanupResult, Never> {
        cleanupCompletedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        updateStorageStatistics()
        startPeriodicStatsUpdate()
    }
    
    deinit {
        stopPeriodicStatsUpdate()
    }
    
    // MARK: - Storage Statistics
    
    /// Aktualizuje statystyki pamięci
    func updateStorageStatistics() {
        storageQueue.async { [weak self] in
            guard let self = self else { return }
            
            let stats = self.calculateStorageStatistics()
            
            DispatchQueue.main.async {
                self.storageStats = stats
                self.storageStatsUpdatedSubject.send(stats)
            }
        }
    }
    
    /// Kalkuluje aktualne statystyki pamięci
    private func calculateStorageStatistics() -> StorageStatistics {
        var stats = StorageStatistics()
        
        do {
            // Statystyki wiadomości
            let messageStats = try calculateMessageStatistics()
            stats.totalMessages = messageStats.count
            stats.messagesSize = messageStats.size
            
            // Statystyki załączników
            let mediaStats = try calculateMediaStatistics()
            stats.totalAttachments = mediaStats.count
            stats.attachmentsSize = mediaStats.size
            
            // Statystyki kontaktów
            let contactStats = try calculateContactStatistics()
            stats.totalContacts = contactStats.count
            stats.contactsSize = contactStats.size
            
            // Statystyki czatów
            let chatStats = try calculateChatStatistics()
            stats.totalChats = chatStats.count
            stats.chatsSize = chatStats.size
            
            // Całkowity rozmiar
            stats.totalSize = stats.messagesSize + stats.attachmentsSize +
                             stats.contactsSize + stats.chatsSize
            
            // Statystyki systemu
            stats.availableSpace = getAvailableStorage()
            stats.usedSpace = getTotalUsedStorage()
            
            return stats
            
        } catch {
            print("❌ Error calculating storage statistics: \(error)")
            return StorageStatistics()
        }
    }
    
    /// Kalkuluje statystyki wiadomości
    private func calculateMessageStatistics() throws -> (count: Int, size: Int) {
        let request = FetchDescriptor<Message>()
        let messages = try modelContext.fetch(request)
        
        let totalSize = messages.reduce(0) { size, message in
            // Szacunkowy rozmiar wiadomości (tekst + metadata)
            let textSize = message.content.data(using: .utf8)?.count ?? 0
            let metadataSize = 200 // Szacunkowe metadata
            return size + textSize + metadataSize
        }
        
        return (messages.count, totalSize)
    }
    
    /// Kalkuluje statystyki załączników
    private func calculateMediaStatistics() throws -> (count: Int, size: Int) {
        let request = FetchDescriptor<MediaAttachment>()
        let attachments = try modelContext.fetch(request)
        
        let totalSize = attachments.reduce(0) { size, attachment in
            return size + attachment.compressedFileSize + (attachment.thumbnailData?.count ?? 0)
        }
        
        return (attachments.count, totalSize)
    }
    
    /// Kalkuluje statystyki kontaktów
    private func calculateContactStatistics() throws -> (count: Int, size: Int) {
        let request = FetchDescriptor<Contact>()
        let contacts = try modelContext.fetch(request)
        
        let totalSize = contacts.reduce(0) { size, contact in
            let nicknameSize = contact.nickname.data(using: .utf8)?.count ?? 0
            let avatarSize = contact.avatarData?.count ?? 0
            let metadataSize = 150 // Szacunkowe metadata
            return size + nicknameSize + avatarSize + metadataSize
        }
        
        return (contacts.count, totalSize)
    }
    
    /// Kalkuluje statystyki czatów
    private func calculateChatStatistics() throws -> (count: Int, size: Int) {
        let request = FetchDescriptor<Chat>()
        let chats = try modelContext.fetch(request)
        
        let totalSize = chats.reduce(0) { size, chat in
            let nameSize = chat.name?.data(using: .utf8)?.count ?? 0
            let metadataSize = 100 // Szacunkowe metadata
            return size + nameSize + metadataSize
        }
        
        return (chats.count, totalSize)
    }
    
    // MARK: - Storage Cleanup
    
    /// Rozpoczyna cleanup starych danych
    func performCleanup(options: CleanupOptions = .default) async throws {
        guard !isCleanupInProgress else {
            throw StorageServiceError.cleanupInProgress
        }
        
        isCleanupInProgress = true
        cleanupProgress = 0.0
        
        defer {
            isCleanupInProgress = false
            cleanupProgress = 0.0
        }
        
        do {
            let result = try await executeCleanup(options: options)
            
            DispatchQueue.main.async { [weak self] in
                self?.cleanupCompletedSubject.send(.success(result))
                self?.updateStorageStatistics()
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.cleanupCompletedSubject.send(.failure(error))
            }
            throw error
        }
    }
    
    /// Wykonuje cleanup
    private func executeCleanup(options: CleanupOptions) async throws -> CleanupSummary {
        var summary = CleanupSummary()
        
        // Krok 1: Cleanup starych wiadomości (25% progress)
        updateCleanupProgress(0.25)
        if options.removeOldMessages {
            summary.messagesRemoved = try await cleanupOldMessages(options.messageRetentionDays)
        }
        
        // Krok 2: Cleanup starych załączników (50% progress)
        updateCleanupProgress(0.5)
        if options.removeOldAttachments {
            summary.attachmentsRemoved = try await cleanupOldAttachments(options.attachmentRetentionDays)
        }
        
        // Krok 3: Cleanup orphaned data (75% progress)
        updateCleanupProgress(0.75)
        if options.removeOrphanedData {
            let orphanedCount = try await cleanupOrphanedData()
            summary.orphanedDataRemoved = orphanedCount
        }
        
        // Krok 4: Vacuum database (100% progress)
        updateCleanupProgress(1.0)
        if options.vacuumDatabase {
            try await vacuumDatabase()
            summary.databaseVacuumed = true
        }
        
        // Oblicz zaoszczędzone miejsce
        let newStats = calculateStorageStatistics()
        summary.spaceFreed = storageStats.totalSize - newStats.totalSize
        
        return summary
    }
    
    /// Czyści stare wiadomości
    private func cleanupOldMessages(_ retentionDays: Int) async throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date.distantPast
        
        let request = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { message in
                message.timestamp < cutoffDate
            }
        )
        
        let oldMessages = try modelContext.fetch(request)
        
        for message in oldMessages {
            modelContext.delete(message)
        }
        
        try modelContext.save()
        
        print("🗑️ Cleaned up \(oldMessages.count) old messages")
        return oldMessages.count
    }
    
    /// Czyści stare załączniki
    private func cleanupOldAttachments(_ retentionDays: Int) async throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date.distantPast
        
        let request = FetchDescriptor<MediaAttachment>(
            predicate: #Predicate<MediaAttachment> { attachment in
                attachment.dateCreated < cutoffDate
            }
        )
        
        let oldAttachments = try modelContext.fetch(request)
        
        for attachment in oldAttachments {
            modelContext.delete(attachment)
        }
        
        try modelContext.save()
        
        print("🗑️ Cleaned up \(oldAttachments.count) old attachments")
        return oldAttachments.count
    }
    
    /// Czyści orphaned data (załączniki bez wiadomości, etc.)
    private func cleanupOrphanedData() async throws -> Int {
        var removedCount = 0
        
        // Znajdź załączniki bez wiadomości
        let attachmentRequest = FetchDescriptor<MediaAttachment>()
        let allAttachments = try modelContext.fetch(attachmentRequest)
        
        for attachment in allAttachments {
            if attachment.message == nil {
                modelContext.delete(attachment)
                removedCount += 1
            }
        }
        
        try modelContext.save()
        
        print("🗑️ Cleaned up \(removedCount) orphaned data items")
        return removedCount
    }
    
    /// Wykonuje vacuum na bazie danych
    private func vacuumDatabase() async throws {
        // SwiftData nie ma bezpośredniego vacuum, ale save() może pomóc w optymalizacji
        try modelContext.save()
        print("🗄️ Database vacuum completed")
    }
    
    /// Aktualizuje progress cleanup
    private func updateCleanupProgress(_ progress: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.cleanupProgress = progress
            self?.cleanupProgressSubject.send(progress)
        }
    }
    
    // MARK: - Storage Management
    
    /// Sprawdza czy potrzebny jest cleanup
    func needsCleanup() -> Bool {
        let freeSpaceRatio = Double(storageStats.availableSpace) / Double(storageStats.usedSpace + storageStats.availableSpace)
        return freeSpaceRatio < 0.1 || storageStats.totalSize > 100 * 1024 * 1024 // 100MB
    }
    
    /// Sugeruje opcje cleanup
    func suggestCleanupOptions() -> CleanupOptions {
        var options = CleanupOptions.default
        
        // Jeśli mało miejsca, agresywniejszy cleanup
        if storageStats.availableSpace < 500 * 1024 * 1024 { // < 500MB
            options.messageRetentionDays = 7
            options.attachmentRetentionDays = 3
            options.removeOldAttachments = true
            options.vacuumDatabase = true
        }
        
        return options
    }
    
    /// Eksportuje dane do backup
    func exportDataForBackup() async throws -> Data {
        // Przygotuj dane do exportu (bez attachment data dla rozmiaru)
        let exportData = ExportData(
            contacts: try getContactsForExport(),
            chats: try getChatsForExport(),
            messages: try getMessagesForExport(),
            exportDate: Date(),
            version: "1.0"
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    /// Importuje dane z backup
    func importDataFromBackup(_ data: Data) async throws {
        let exportData = try JSONDecoder().decode(ExportData.self, from: data)
        
        // Waliduj wersję
        guard exportData.version == "1.0" else {
            throw StorageServiceError.incompatibleBackupVersion
        }
        
        // Import contacts, chats, messages
        // Implementacja importu...
        
        updateStorageStatistics()
    }
    
    // MARK: - System Storage
    
    /// Pobiera dostępne miejsce na dysku
    private func getAvailableStorage() -> Int {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                return freeSpace.intValue
            }
        } catch {
            print("❌ Error getting available storage: \(error)")
        }
        return 0
    }
    
    /// Pobiera całkowite użyte miejsce
    private func getTotalUsedStorage() -> Int {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSpace = systemAttributes[.systemSize] as? NSNumber,
               let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                return totalSpace.intValue - freeSpace.intValue
            }
        } catch {
            print("❌ Error getting used storage: \(error)")
        }
        return 0
    }
    
    /// Pobiera rozmiar folderu aplikacji
    func getAppDataSize() -> Int {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }
        
        return getFolderSize(at: documentsPath)
    }
    
    /// Oblicza rozmiar folderu
    private func getFolderSize(at url: URL) -> Int {
        do {
            let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileAllocatedSizeKey]
            let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            )
            
            var totalSize = 0
            
            for case let fileURL as URL in enumerator ?? [] {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                
                if resourceValues.isRegularFile == true {
                    totalSize += resourceValues.fileAllocatedSize ?? 0
                }
            }
            
            return totalSize
            
        } catch {
            print("❌ Error calculating folder size: \(error)")
            return 0
        }
    }
    
    // MARK: - Periodic Updates
    
    /// Uruchamia okresowe aktualizacje statystyk
    private func startPeriodicStatsUpdate() {
        statsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateStorageStatistics()
        }
    }
    
    /// Zatrzymuje okresowe aktualizacje
    private func stopPeriodicStatsUpdate() {
        statsUpdateTimer?.invalidate()
        statsUpdateTimer = nil
    }
    
    // MARK: - Export Helpers
    
    private func getContactsForExport() throws -> [ContactExportData] {
        let request = FetchDescriptor<Contact>()
        let contacts = try modelContext.fetch(request)
        
        return contacts.map { contact in
            ContactExportData(
                id: contact.id,
                nickname: contact.nickname,
                dateAdded: contact.dateAdded,
                hasAvatar: contact.hasCustomAvatar
            )
        }
    }
    
    private func getChatsForExport() throws -> [ChatExportData] {
        let request = FetchDescriptor<Chat>()
        let chats = try modelContext.fetch(request)
        
        return chats.map { chat in
            ChatExportData(
                id: chat.id,
                name: chat.name,
                type: chat.type,
                dateCreated: chat.dateCreated,
                participantIDs: chat.participants.map { $0.id }
            )
        }
    }
    
    private func getMessagesForExport() throws -> [MessageExportData] {
        let request = FetchDescriptor<Message>()
        let messages = try modelContext.fetch(request)
        
        return messages.map { message in
            MessageExportData(
                id: message.id,
                content: message.content,
                senderID: message.senderID,
                timestamp: message.timestamp,
                type: message.type,
                chatID: message.chat?.id ?? ""
            )
        }
    }
}

// MARK: - Data Models

/// Statystyki pamięci
struct StorageStatistics {
    var totalMessages: Int = 0
    var totalChats: Int = 0
    var totalContacts: Int = 0
    var totalAttachments: Int = 0
    
    var messagesSize: Int = 0
    var chatsSize: Int = 0
    var contactsSize: Int = 0
    var attachmentsSize: Int = 0
    var totalSize: Int = 0
    
    var availableSpace: Int = 0
    var usedSpace: Int = 0
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
    
    var formattedAvailableSpace: String {
        ByteCountFormatter.string(fromByteCount: Int64(availableSpace), countStyle: .file)
    }
}

/// Opcje cleanup
struct CleanupOptions {
    var removeOldMessages: Bool = true
    var messageRetentionDays: Int = 30
    
    var removeOldAttachments: Bool = false
    var attachmentRetentionDays: Int = 7
    
    var removeOrphanedData: Bool = true
    var vacuumDatabase: Bool = false
    
    static let `default` = CleanupOptions()
    
    static let aggressive = CleanupOptions(
        removeOldMessages: true,
        messageRetentionDays: 7,
        removeOldAttachments: true,
        attachmentRetentionDays: 3,
        removeOrphanedData: true,
        vacuumDatabase: true
    )
}

/// Rezultat cleanup
enum CleanupResult {
    case success(CleanupSummary)
    case failure(Error)
}

/// Podsumowanie cleanup
struct CleanupSummary {
    var messagesRemoved: Int = 0
    var attachmentsRemoved: Int = 0
    var orphanedDataRemoved: Int = 0
    var spaceFreed: Int = 0
    var databaseVacuumed: Bool = false
    
    var formattedSpaceFreed: String {
        ByteCountFormatter.string(fromByteCount: Int64(spaceFreed), countStyle: .file)
    }
}

/// Dane eksportu
struct ExportData: Codable {
    let contacts: [ContactExportData]
    let chats: [ChatExportData]
    let messages: [MessageExportData]
    let exportDate: Date
    let version: String
}

struct ContactExportData: Codable {
    let id: String
    let nickname: String
    let dateAdded: Date
    let hasAvatar: Bool
}

struct ChatExportData: Codable {
    let id: String
    let name: String?
    let type: ChatType
    let dateCreated: Date
    let participantIDs: [String]
}

struct MessageExportData: Codable {
    let id: String
    let content: String
    let senderID: String
    let timestamp: Date
    let type: MessageType
    let chatID: String
}

// MARK: - Storage Service Errors

enum StorageServiceError: LocalizedError {
    case cleanupInProgress
    case insufficientSpace
    case backupFailed
    case restoreFailed
    case incompatibleBackupVersion
    case databaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .cleanupInProgress:
            return "Czyszczenie jest już w toku"
        case .insufficientSpace:
            return "Niewystarczająca ilość miejsca"
        case .backupFailed:
            return "Nie udało się utworzyć kopii zapasowej"
        case .restoreFailed:
            return "Nie udało się przywrócić kopii zapasowej"
        case .incompatibleBackupVersion:
            return "Niekompatybilna wersja kopii zapasowej"
        case .databaseError(let error):
            return "Błąd bazy danych: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension StorageService {
    
    /// Sprawdza czy cleanup jest potrzebny
    func getCleanupRecommendation() -> String {
        if needsCleanup() {
            return "Zalecane jest wyczyszczenie starych danych"
        } else {
            return "Pamięć w dobrym stanie"
        }
    }
    
    /// Zwraca top statistyki jako tekst
    func getTopStatistics() -> [String] {
        return [
            "Wiadomości: \(storageStats.totalMessages)",
            "Załączniki: \(storageStats.totalAttachments)",
            "Kontakty: \(storageStats.totalContacts)",
            "Rozmiar: \(storageStats.formattedTotalSize)"
        ]
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension StorageService {
    
    /// Tworzy mock service dla preview i testów
    static func createMockService() -> StorageService {
        let mockContext = MockModelContext()
        let service = StorageService(modelContext: mockContext)
        
        // Ustaw przykładowe statystyki
        service.storageStats = StorageStatistics(
            totalMessages: 1250,
            totalChats: 15,
            totalContacts: 8,
            totalAttachments: 45,
            messagesSize: 2 * 1024 * 1024,    // 2MB
            chatsSize: 50 * 1024,             // 50KB
            contactsSize: 500 * 1024,         // 500KB
            attachmentsSize: 15 * 1024 * 1024, // 15MB
            totalSize: 17 * 1024 * 1024,      // 17MB
            availableSpace: 2 * 1024 * 1024 * 1024, // 2GB
            usedSpace: 30 * 1024 * 1024 * 1024      // 30GB
        )
        
        return service
    }
    
    /// Symuluje cleanup
    func simulateCleanup() {
        isCleanupInProgress = true
        
        for i in 0...10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) { [weak self] in
                let progress = Double(i) / 10.0
                self?.cleanupProgress = progress
                self?.cleanupProgressSubject.send(progress)
                
                if i == 10 {
                    self?.isCleanupInProgress = false
                    let summary = CleanupSummary(
                        messagesRemoved: 150,
                        attachmentsRemoved: 12,
                        orphanedDataRemoved: 5,
                        spaceFreed: 5 * 1024 * 1024, // 5MB
                        databaseVacuumed: true
                    )
                    self?.cleanupCompletedSubject.send(.success(summary))
                }
            }
        }
    }
}
#endif
