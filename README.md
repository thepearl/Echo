# Echo

Echo is a flexible and easy-to-use logging framework for Swift applications. It is made with internal testers in mind. It provides a robust solution for capturing, storing, and analyzing log data in iOS applications in order to simplify exchanges between devs and internal testers.

# Table of Contents

1. [Features](#features)
2. [Requirements](#requirements)
3. [Installation](#installation)
   - [Swift Package Manager](#swift-package-manager)
4. [Usage](#usage)
   - [Basic Logging](#basic-logging)
   - [Custom Configuration](#custom-configuration)
5. [Configuration Options](#configuration-options)
6. [SwiftUI Integration](#swiftui-integration)
7. [UIKit Integration](#uikit-integration)
8. [Built-in Log Viewer](#built-in-log-viewer)
9. [Visualizing and Exporting Logs](#visualizing-and-exporting-logs)
    - [In-App Log Visualization](#in-app-log-visualization)
    - [Exporting Logs for Analysis](#exporting-logs-for-analysis)
    - [Advanced Visualization and Analysis](#advanced-visualization-and-analysis)
10. [License](#license)

## Features

- Multiple log levels (Debug, Info, Warning, Error, Critical)
- Customizable log categories
- In-memory and persistent storage of logs
- Log rotation and archiving
- Crash log capture
- Comprehensive log viewer with filtering and sorting capabilities
- SwiftUI and UIKit compatibility
- Thread-safe logging operations

## Requirements

- iOS 14.0+
- Swift 5.10+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Echo.git", from: "1.0.0")
]
```

## Usage

### Basic Logging

```swift
import Echo

let logger = Echo.Logger()
logger.log(.info, category: .network, message: "API request started")
logger.log(.error, category: .database, message: "Failed to save data")
```

### Custom Configuration

```swift
let config = Echo.LoggerConfiguration(
    minimumLogLevel: .debug,
    maxLogEntries: 5000,
    logRotationInterval: 86400 // 24 hours
)
let logger = Echo.Logger(configuration: config)
```

### Configuration Options

The following table explains the available configuration options for Echo:

| Option | Type | Default | Description | Progress |
|--------|------|---------|-------------|----------|
| minimumLogLevel | LogLevel | .debug | The minimum severity level of logs to be captured. Logs below this level will be ignored. | ✅ |
| maxLogEntries | Int | 10000 | The maximum number of log entries to keep in memory and storage. | ✅ |
| logRotationInterval | TimeInterval | 86400 (24 hours) | The time interval in seconds after which logs are rotated (archived and cleared). | ✅ |
| activeTimeRange | ClosedRange<Date>? | nil | An optional time range during which logging is active. If nil, logging is always active. | ✅ |
| persistenceStrategy | PersistenceStrategy | .fileSystem | Defines how logs are persisted. Options include .fileSystem, .coreData, or .inMemory. | 🚧 |
| encryptionKey | String? | nil | An optional encryption key for securing stored logs. If provided, logs will be encrypted at rest. | 🚧 |
| compressionEnabled | Bool | false | If true, logs will be compressed before storage to save space. | 🚧 |
| networkLogOptions | NetworkLogOptions | .all | Configures what network-related information to log (e.g., headers, body, response). | 🚧 | 
| customFields | [String: Any] | [:] | Additional custom fields to include with each log entry. | 🚧 |

### SwiftUI Integration

```swift
struct ContentView: View {
    @StateObject private var logger = Echo.Logger()

    var body: some View {
        NavigationView {
            Text("Hello, World!")
                .logPageAppearance(pageName: "ContentView")
        }
        .environmentObject(logger)
    }
}
```

### UIKit Integration

```swift
class ViewController: UIViewController {
    let logger = Echo.Logger()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logPageAppearance(logger: logger, pageName: "ViewController")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logPageDisappearance(logger: logger, pageName: "ViewController")
    }
}
```

## Built-in Log Viewer

Echo provides a built-in log viewer for easy visualization and analysis of logs within your app:

```swift
struct LogViewerScreen: View {
    @StateObject private var logger = Echo.Logger()
    
    var body: some View {
        LogViewer()
            .environmentObject(logger)
    }
}
```
<img src="https://github.com/user-attachments/assets/19e070e5-f27c-47dd-be62-f92bb30ea63d" height="600" width="275" />

The Log Viewer interface includes:
- A navigation bar with "Logs" as the title, and "Filter", sort, and share buttons.
- A search bar for filtering logs.
- A list of log entries, each showing:
  - A brief description of the log message
  - A category tag (e.g., "Database", "Business Logic", "Authentication")
  - A severity level tag (e.g., "warning", "critical", "error", "debug", "info")
  - A timestamp for each log entry

This interface allows for easy browsing, searching, and analysis of logs directly within your app.

## Visualizing and Exporting Logs

Echo provides built-in capabilities for visualizing logs directly within your app and exporting them for further analysis by developers.

### In-App Log Visualization

The `LogViewer` component offers a comprehensive interface for viewing, filtering, and analyzing logs directly within your app. Key features include:
- Real-time log display
- Filtering by log level, category, and date range
- Full-text search across log messages
- Detailed view for individual log entries

### Exporting Logs for Analysis

Echo makes it easy to export logs for offline analysis or sharing with your development team:

```swift
let logger = Echo.Logger()

// Export logs as a formatted string
let exportedLogs = logger.exportLogs()

// Share logs using UIActivityViewController
let activityVC = UIActivityViewController(activityItems: [exportedLogs], applicationActivities: nil)
present(activityVC, animated: true)
```

Exported logs can be:
- Shared via email, messaging apps, or cloud storage
- Imported into analysis tools or spreadsheets
- Used for debugging sessions or bug reports

### Advanced Visualization and Analysis

For more advanced visualization and analysis, there is work in progress to consider these approaches:

1. **Expand LogConfiguratons** Add some more configurations (mentionned in the table) to make Echo even more flexible to work with.
2. **Custom Dashboards**: Create custom SwiftUI views to visualize log data in charts or graphs that can be opened in mac-os. 
3. **Integration with Analytics Tools**: Export logs in a format compatible with popular analytics platforms.
4. **Automated Reports**: Set up automated processes to generate daily or weekly log summaries for your development team.

By leveraging these visualization and export features, Echo will enable developers and testers to gain deeper insights into app behavior, streamline debugging processes, and facilitate effective communication within development teams.

## License

Echo is available under the MIT license. See the LICENSE file for more info.
