//
//  AirLinkApp.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI
import SwiftData

@main
struct AirLinkApp: App {
    
    // MARK: - SwiftData Container
    private let modelContainer: ModelContainer
    
    init() {
        // Konfiguracja modeli SwiftData (bez CloudKit!)
        let schema = Schema([
            Contact.self,
            Chat.self,
            Message.self,
            MediaAttachment.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Ważne: BEZ chmury!
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Nie udało się utworzyć ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer)
                .preferredColorScheme(nil) // Obsługa Light & Dark mode
        }
    }
}

// MARK: - Orientacja aplikacji
extension AirLinkApp {
    /// Wymusza orientację pionową w całej aplikacji
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        }
    }
}
