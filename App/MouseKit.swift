//
//  Mousekit.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import SwiftUI

@main
struct MouseKit: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }

    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // App is going to background, disconnect gracefully
            Task { @MainActor in
                await ConnectionManager.shared.disconnect()
            }
        case .active:
            // App is becoming active
            break
        case .inactive:
            // App is becoming inactive (e.g., control center opened)
            break
        @unknown default:
            break
        }
    }
}
