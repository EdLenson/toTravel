//
//  toTravelApp.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI
import SwiftData

@main
struct ToTravelApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Passport.self,
            Visa.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Task { @MainActor in
                let context = container.mainContext
                let visas = try context.fetch(FetchDescriptor<Visa>())
                for visa in visas {
                    if visa.passport == nil {
                        print("Удаляем осиротевшую визу: \(visa.customName)")
                        context.delete(visa)
                    }
                }
                try context.save()
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
