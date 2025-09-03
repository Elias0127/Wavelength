//
//  WavelengthApp.swift
//  Wavelength
//
//  Created by Elias Woldie on 9/3/25.
//

import SwiftUI

@main
struct WavelengthApp: App {
    let coreDataManager = CoreDataManager.shared
    
    init() {
        // Initialize Core Data and perform initial setup
        coreDataManager.performInitialSetup()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
        }
    }
}
