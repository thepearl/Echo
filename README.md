# Echo 🔊

A comprehensive logging system for iOS applications that provides robust logging capabilities with support for network request tracking, persistence, and visualization.

## Features

- **📊 Multiple Log Levels**: Debug, Info, Warning, Error, and Critical
- **🏷️ Log Categories**: Organize logs by application areas (Network, UI, Database, etc.)
- **🌐 Network Request Monitoring**: Automatic HTTP request/response logging
- **💾 Persistent Storage**: Core Data-based log persistence with rotation
- **📱 Visual Log Viewer**: SwiftUI-based log viewer with filtering and search
- **🔍 Advanced Filtering**: Filter by level, category, date range, and search terms
- **📤 Export Capabilities**: Export logs for analysis or sharing
- **⚡ Performance Monitoring**: Track view rendering performance
- **🎯 SwiftUI Modifiers**: Easy integration with declarative logging modifiers

## Installation

### Swift Package Manager

Add Echo to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/thepearl/Echo.git", branch: "master")
]
```

## Quick Start

### Basic Logging

```swift
import Echo

// Create a logger instance
let logger = Echo.Logger()

// Log messages with different levels
logger.log(.info, category: .network, message: "API request started")
logger.log(.error, category: .database, message: "Failed to save user data")
logger.log(.warning, category: .userInterface, message: "Slow animation detected")
```

### Network Logging

Enable automatic network request logging:

```swift
// Enable network logging
logger.enableNetworkLogging()

// Use URLSession with Echo's configuration
let session = URLSession(configuration: Echo.urlSessionConfiguration())

// All network requests will now be automatically logged
```

### SwiftUI Integration

```swift
import SwiftUI
import Echo

struct ContentView: View {
    let logger = Echo.Logger()
    
    var body: some View {
        VStack {
            Text("Welcome")
                .echoPageAppearance(logger: logger, pageName: "Home Screen")
                .echoUserInteraction(logger: logger, interactionName: "Welcome Text")
        }
        .echoViewLifecycle(logger: logger, viewName: "ContentView")
    }
}
```

## Configuration

Customize the logger behavior with `LoggerConfiguration`:

```swift
let config = Echo.LoggerConfiguration(
    minimumLogLevel: .info,        // Only log info and above
    maxLogEntries: 5000,           // Keep up to 5000 log entries
    logRotationInterval: 86400,    // Rotate logs daily
    activeTimeRange: nil           // Log 24/7 (or specify time range)
)

let logger = Echo.Logger(configuration: config)
```

## Log Levels

Echo supports five log levels in order of severity:

- **Debug**: Detailed information for debugging
- **Info**: General information about program execution
- **Warning**: Potentially harmful situations
- **Error**: Error events that might allow the application to continue
- **Critical**: Severe error events that may lead to application termination

## Log Categories

Built-in categories help organize your logs:

- `uncategorized`: Default category
- `network`: Network-related operations
- `userInterface`: UI interactions and lifecycle
- `lifecycle`: Application/view lifecycle events
- `database`: Database operations
- `authentication`: Authentication and security
- `businessLogic`: Core business logic
- `performance`: Performance monitoring

Create custom categories:

```swift
let customCategory = Echo.LogCategory("CustomFeature")
logger.log(.info, category: customCategory, message: "Custom feature activated")
```

## Visual Log Viewer

Display logs in your app with the built-in SwiftUI viewer:

```swift
import SwiftUI
import Echo

struct LogViewerScreen: View {
    let logger = Echo.Logger()
    
    var body: some View {
        LogViewer(logger: logger)
    }
}
```

The log viewer includes:
- **Search**: Filter logs by message content
- **Level Filtering**: Show/hide specific log levels
- **Category Filtering**: Filter by log categories
- **Date Range Filtering**: View logs from specific time periods
- **Sorting**: Sort by timestamp, level, or category
- **Export**: Share logs via system share sheet
- **Detail View**: Tap any log for detailed information including network details

## SwiftUI Modifiers

Echo provides convenient SwiftUI modifiers for declarative logging:

### Page Appearance Logging

```swift
ContentView()
    .echoPageAppearance(
        logger: logger,
        pageName: "Settings Screen",
        category: .userInterface,
        level: .info
    )
```

### View Lifecycle Logging

```swift
UserProfileView()
    .echoViewLifecycle(
        logger: logger,
        viewName: "UserProfile",
        category: .lifecycle,
        level: .info,
        logDisappear: true
    )
```

### User Interaction Logging

```swift
Button("Save") { saveData() }
    .echoUserInteraction(
        logger: logger,
        interactionName: "Save Button",
        category: .userInterface,
        level: .info
    )
```

### Navigation Logging

```swift
DetailView()
    .echoNavigation(
        logger: logger,
        screenName: "Product Detail",
        screenData: ["productId": product.id, "category": product.category]
    )
```

### Performance Monitoring

```swift
ComplexView()
    .echoPerformance(logger: logger, viewName: "ComplexView")
```

### Combined Logging

```swift
MainView()
    .echoPageAndInteractions(
        logger: logger,
        name: "Main Screen",
        category: .userInterface,
        level: .info
    )
```

## Advanced Features

### Network Request Details

When network logging is enabled, Echo captures comprehensive request/response data:

- Request URL, method, headers, and body
- Response status code, headers, and body
- Request duration
- Error details (if any)

### Log Export

Export logs programmatically:

```swift
let exportedLogs = logger.exportLogs()
// Share or save the exported log string
```

### Log Management

```swift
// Clear all logs
logger.clearLogs()

// Flush pending logs to storage
logger.flushBuffer()

// Disable network logging
logger.disableNetworkLogging()
```

### Persistent Storage

Echo automatically manages log persistence using Core Data:
- Logs are saved to device storage
- Automatic log rotation based on configuration
- Archived logs are saved as JSON files
- Efficient memory management with buffering

## Best Practices

1. **Use Appropriate Log Levels**: Reserve `.critical` for severe errors, use `.debug` for detailed troubleshooting
2. **Categorize Logs**: Use specific categories to organize logs by feature or component
3. **Include Context**: Provide meaningful messages with relevant context
4. **Monitor Performance**: Use performance logging for views that might be slow
5. **Configure Limits**: Set appropriate `maxLogEntries` to balance storage and performance
6. **Network Logging**: Be mindful of sensitive data in network requests when logging is enabled

## Example App Integration

```swift
import SwiftUI
import Echo

@main
struct MyApp: App {
    let logger = Echo.Logger(configuration: Echo.LoggerConfiguration(
        minimumLogLevel: .info,
        maxLogEntries: 10000
    ))
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(logger)
                .onAppear {
                    logger.enableNetworkLogging()
                    logger.log(.info, category: .lifecycle, message: "App launched")
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var logger: Echo.Logger
    @State private var showingLogs = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Your app content
                Text("My App")
                
                Button("View Logs") {
                    showingLogs = true
                }
            }
            .echoPageAppearance(logger: logger, pageName: "Main Screen")
            .sheet(isPresented: $showingLogs) {
                LogViewer(logger: logger)
            }
        }
    }
}
```

## Requirements

- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+
- Swift 5.3+
- Xcode 12.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Echo is available under the MIT license. See the LICENSE file for more info.

---

**Echo** - Making iOS debugging more transparent, one log at a time. 🔊
