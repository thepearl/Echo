//
//  Modifiers.swift
//  Echo
//
//  Created by Ghazi Tozri on 6/26/25.
//

import SwiftUI

// MARK: - SwiftUI Extensions for Echo Logger

/// A view modifier that logs page appearance events
public struct PageAppearanceLoggerModifier: ViewModifier {
    let pageName: String
    let category: Echo.LogCategory
    let level: Echo.LogLevel
     var logger: Echo.Logger

    public func body(content: Content) -> some View {
        content
            .onAppear {
                logger.log(
                    level,
                    category: category,
                    message: "Page appeared: \(pageName)"
                )
            }
            .onDisappear {
                logger.log(
                    level,
                    category: category,
                    message: "Page disappeared: \(pageName)"
                )
            }
    }
}

/// A view modifier that logs view lifecycle events with more detail
public struct ViewLifecycleLoggerModifier: ViewModifier {
    let viewName: String
    let category: Echo.LogCategory
    let level: Echo.LogLevel
    let logDisappear: Bool
     var logger: Echo.Logger
    @State private var appearanceTime: Date?

    public func body(content: Content) -> some View {
        content
            .onAppear {
                let timestamp = Date()
                appearanceTime = timestamp
                logger.log(
                    level,
                    category: category,
                    message: "View lifecycle - \(viewName): appeared"
                )
            }
            .onDisappear {
                guard logDisappear else { return }

                let duration = appearanceTime?.timeIntervalSinceNow.magnitude ?? 0
                logger.log(
                    level,
                    category: category,
                    message: "View lifecycle - \(viewName): disappeared (visible for \(String(format: "%.2f", duration))s)"
                )
            }
    }
}

/// A view modifier that logs user interactions
public struct UserInteractionLoggerModifier: ViewModifier {
    let interactionName: String
    let category: Echo.LogCategory
    let level: Echo.LogLevel
     var logger: Echo.Logger

    public func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        logger.log(
                            level,
                            category: category,
                            message: "User interaction - \(interactionName): tapped"
                        )
                    }
            )
    }
}

// MARK: - View Extensions

public extension View {
    /// Logs when a page/view appears and disappears
    /// - Parameters:
    ///   - pageName: The name of the page/view to log
    ///   - category: The log category (defaults to .userInterface)
    ///   - level: The log level (defaults to .info)
    /// - Returns: A view that logs appearance events
    func echoPageAppearance(
        logger: Echo.Logger,
        pageName: String,
        category: Echo.LogCategory = .userInterface,
        level: Echo.LogLevel = .info
    ) -> some View {
        self.modifier(PageAppearanceLoggerModifier(
            pageName: pageName,
            category: category,
            level: level,
            logger: logger
        ))
    }

    /// Logs detailed view lifecycle events including time spent on view
    /// - Parameters:
    ///   - viewName: The name of the view to log
    ///   - category: The log category (defaults to .lifecycle)
    ///   - level: The log level (defaults to .info)
    ///   - logDisappear: Whether to log disappear events (defaults to true)
    /// - Returns: A view that logs lifecycle events
    func echoViewLifecycle(
        logger: Echo.Logger,
        viewName: String,
        category: Echo.LogCategory = .lifecycle,
        level: Echo.LogLevel = .info,
        logDisappear: Bool = true
    ) -> some View {
        self.modifier(ViewLifecycleLoggerModifier(
            viewName: viewName,
            category: category,
            level: level,
            logDisappear: logDisappear,
            logger: logger
        ))
    }

    /// Logs user tap interactions
    /// - Parameters:
    ///   - interactionName: The name of the interaction to log
    ///   - category: The log category (defaults to .userInterface)
    ///   - level: The log level (defaults to .info)
    /// - Returns: A view that logs tap interactions
    func echoUserInteraction(
        logger: Echo.Logger,
        interactionName: String,
        category: Echo.LogCategory = .userInterface,
        level: Echo.LogLevel = .info
    ) -> some View {
        self.modifier(UserInteractionLoggerModifier(
            interactionName: interactionName,
            category: category,
            level: level,
            logger: logger
        ))
    }

    /// Logs both page appearance and user interactions
    /// - Parameters:
    ///   - name: The name to use for both page and interaction logging
    ///   - category: The log category (defaults to .userInterface)
    ///   - level: The log level (defaults to .info)
    /// - Returns: A view that logs both appearance and interaction events
    func echoPageAndInteractions(
        logger: Echo.Logger,
        name: String,
        category: Echo.LogCategory = .userInterface,
        level: Echo.LogLevel = .info
    ) -> some View {
        self
            .echoPageAppearance(logger: logger, pageName: name, category: category, level: level)
            .echoUserInteraction(logger: logger, interactionName: name, category: category, level: level)
    }
}

// MARK: - Advanced Logging Modifiers

/// A more advanced view modifier that logs navigation events
public struct NavigationLoggerModifier: ViewModifier {
    let screenName: String
    let screenData: [String: Any]?
     var logger: Echo.Logger
    @State private var navigationStartTime: Date?

    public func body(content: Content) -> some View {
        content
            .onAppear {
                navigationStartTime = Date()
                var message = "Navigation - Entered screen: \(screenName)"

                if let data = screenData {
                    let dataString = data.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                    message += " with data: [\(dataString)]"
                }

                logger.log(
                    .info,
                    category: .userInterface,
                    message: message
                )
            }
            .onDisappear {
                guard let startTime = navigationStartTime else { return }
                let duration = Date().timeIntervalSince(startTime)

                logger.log(
                    .info,
                    category: .userInterface,
                    message: "Navigation - Exited screen: \(screenName) (duration: \(String(format: "%.2f", duration))s)"
                )
            }
    }
}

public extension View {
    /// Logs navigation events with optional screen data
    /// - Parameters:
    ///   - screenName: The name of the screen
    ///   - screenData: Optional data associated with the screen
    /// - Returns: A view that logs navigation events
    func echoNavigation(
        logger: Echo.Logger,
        screenName: String,
        screenData: [String: Any]? = nil
    ) -> some View {
        self.modifier(NavigationLoggerModifier(
            screenName: screenName,
            screenData: screenData,
            logger: logger
        ))
    }
}

// MARK: - Performance Logging

/// A view modifier that logs view rendering performance
public struct PerformanceLoggerModifier: ViewModifier {
    let viewName: String
     var logger: Echo.Logger
    @State private var renderStartTime: Date?

    public func body(content: Content) -> some View {
        content
            .onAppear {
                renderStartTime = Date()
            }
            .background(
                // This will be called after the view is rendered
                Color.clear
                    .onAppear {
                        guard let startTime = renderStartTime else { return }
                        let renderTime = Date().timeIntervalSince(startTime)

                        if renderTime > 0.1 {
                            logger.log(
                                .warning,
                                category: .performance,
                                message: "Performance - Slow render detected for \(viewName): \(String(format: "%.3f", renderTime))s"
                            )
                        }
                    }
            )
    }
}

public extension View {
    /// Logs performance metrics for view rendering
    /// - Parameter viewName: The name of the view to monitor
    /// - Returns: A view that logs performance metrics
    func echoPerformance(logger: Echo.Logger, viewName: String) -> some View {
        self.modifier(PerformanceLoggerModifier(viewName: viewName, logger: logger))
    }
}
