//
//  looklabApp.swift
//  looklab
//
//  Created by Utku Sen on 30/08/2025.
//

import SwiftUI
import SwiftData

@main
struct LookLabApp: App {
    let modelContainer: ModelContainer
    
    init() {
        // Configure Firebase
        FirebaseManager.shared.configure()
        
        // Initialize SwiftData model container
        do {
            modelContainer = try ModelContainer(for: User.self, ClothingItem.self, Look.self)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        }
    }
}
