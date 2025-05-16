//
//  EchoExampleApp.swift
//  EchoExample
//
//  Created by Ghazi Tozri on 12/09/2024.
//

import SwiftUI
import Echo

@main
struct EchoExampleApp: App {
    @StateObject private var logger = Echo.Logger(configuration: Echo.LoggerConfiguration(
        minimumLogLevel: .debug,
        maxLogEntries: 1000,
        logRotationInterval: 30 // 30 seconds for demo purposes, typically this would be longer
    ))
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(logger)
                  .onAppear {
                      logger.log(.info, category: .lifecycle, message: "EchoExampleApp launched successfully")
                  }
                  .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                      logger.log(.info, category: .lifecycle, message: "App entered background")
                      logger.flushBuffer() // Ensure logs are saved when app goes to background
                  }
                  .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                      logger.log(.info, category: .lifecycle, message: "App will enter foreground")
                  }
        }
    }
}
