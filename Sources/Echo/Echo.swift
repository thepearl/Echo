//
//  Echo.swift
//  Echo
//
//  Created by Ghazi Tozri on 21/08/2024.

import Foundation
import SwiftUI
import Combine
import CoreData
import UIKit

/// A centralized logging system for iOS applications that provides comprehensive logging capabilities
/// with support for network request tracking, persistence, and visualization.
///
/// Echo provides a robust logging infrastructure that helps developers track, store, and analyze application
/// events and network interactions. It includes features such as:
/// - Multiple log levels and categories
/// - Network request monitoring
/// - Persistent storage using Core Data
/// - Log rotation and archiving
/// - Visual log viewer interface
///
/// # Example Usage
/// ```swift
/// let logger = Echo.Logger()
/// logger.log(.info, category: .network, message: "API request started")
/// ```
public struct Echo {
    /// A shared instance of the Echo struct for convenience.
    public static let shared = Echo()
    
    private init() {}
    
    /// Represents the severity or importance of a log entry.
    ///
    /// Log levels are ordered from least severe (debug) to most severe (critical) and are used
    /// to categorize log entries based on their significance.
    ///
    /// # Available Levels
    /// - `debug`: Detailed information for debugging purposes
    /// - `info`: General information about program execution
    /// - `warning`: Potentially harmful situations
    /// - `error`: Error events that might still allow the application to continue
    /// - `critical`: Very severe error events that may lead to application termination
    public enum LogLevel: String, Codable, CaseIterable, Comparable {
        case debug
        case info
        case warning
        case error
        case critical
        
        /// Compares two LogLevels based on their severity.
        ///
        /// - Parameters:
        ///   - lhs: The left-hand side LogLevel to compare.
        ///   - rhs: The right-hand side LogLevel to compare.
        /// - Returns: True if the left-hand side is less severe than the right-hand side.
        public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            let order: [LogLevel] = [.debug, .info, .warning, .error, .critical]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
        
        /// The color associated with each log level for visual distinction.
        var color: Color {
            switch self {
            case .debug: return .gray
            case .info: return .blue
            case .warning: return .yellow
            case .error: return .orange
            case .critical: return .red
            }
        }
    }
    
    /// Represents the area or component of the application that a log entry is associated with.
    ///
    /// Log categories help organize log entries based on different parts or features of the application.
    /// The system provides several predefined categories and allows for custom categories to be created.
    public struct LogCategory: Hashable, Codable {
        /// The name of the category.
        public let name: String
        
        /// Initializes a new LogCategory with the given name.
        ///
        /// - Parameter name: The name of the category.
        public init(_ name: String) {
            self.name = name
        }
        
        /// Predefined categories for common use cases.
        public static let uncategorized = LogCategory("Uncategorized")
        public static let network = LogCategory("Network")
        public static let userInterface = LogCategory("User Interface")
        public static let lifecycle = LogCategory("Lifecycle")
        public static let database = LogCategory("Database")
        public static let authentication = LogCategory("Authentication")
        public static let businessLogic = LogCategory("Business Logic")
        public static let performance = LogCategory("Performance")
    }
    
    /// Represents a single log entry in the Echo logging system.
    ///
    /// A LogEntry contains all information about a logging event, including its message,
    /// severity level, category, source location, and optional network details.
    public struct LogEntry: Identifiable, Codable {
        /// A unique identifier for the log entry.
        public let id: UUID
        /// The timestamp when the log entry was created.
        public let timestamp: Date
        /// The severity level of the log entry.
        public let level: LogLevel
        /// The category associated with the log entry.
        public let category: LogCategory
        /// The main message content of the log entry.
        public let message: String
        /// The name of the file where the log was created.
        public let fileName: String
        /// The name of the function where the log was created.
        public let functionName: String
        /// The line number in the file where the log was created.
        public let lineNumber: Int
        /// Additional network-related details for network log entries.
        public var networkDetails: NetworkLogDetails?
        
        /// Initializes a new LogEntry with the given parameters.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the log entry. Defaults to a new UUID.
        ///   - timestamp: The time when the log entry was created. Defaults to the current date and time.
        ///   - level: The severity level of the log entry.
        ///   - category: The category of the log entry. Defaults to .uncategorized.
        ///   - message: The main content of the log entry.
        ///   - fileName: The name of the file where the log was created.
        ///   - functionName: The name of the function where the log was created.
        ///   - lineNumber: The line number in the file where the log was created.
        ///   - networkDetails: Additional network-related details for network log entries.
        public init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            level: LogLevel,
            category: LogCategory = .uncategorized,
            message: String,
            fileName: String,
            functionName: String,
            lineNumber: Int,
            networkDetails: NetworkLogDetails? = nil
        ) {
            self.id = id
            self.timestamp = timestamp
            self.level = level
            self.category = category
            self.message = message
            self.fileName = fileName
            self.functionName = functionName
            self.lineNumber = lineNumber
            self.networkDetails = networkDetails
        }
    }
    
    /// Contains detailed information about a network request and response.
    public struct NetworkLogDetails: Codable {
        /// The URL of the network request.
        public let url: String
        /// The HTTP method used for the request.
        public let method: String
        /// The headers sent with the request.
        public let requestHeaders: [String: String]
        /// The body of the request, if any.
        public let requestBody: String?
        /// The HTTP status code of the response.
        public let responseStatus: Int
        /// The headers received with the response.
        public let responseHeaders: [String: String]
        /// The body of the response, if any.
        public let responseBody: String?
    }
    
    /// Configuration options for the Echo Logger.
    public struct LoggerConfiguration {
        /// The minimum log level to be captured and stored.
        public var minimumLogLevel: LogLevel
        /// The maximum number of log entries to keep in memory and storage.
        public var maxLogEntries: Int
        /// The time interval for log rotation in seconds.
        public var logRotationInterval: TimeInterval
        /// The time range during which logging is active.
        public var activeTimeRange: ClosedRange<Date>?
        
        /// Initializes a new LoggerConfiguration with the specified parameters.
        ///
        /// - Parameters:
        ///   - minimumLogLevel: The minimum log level to capture. Defaults to .debug.
        ///   - maxLogEntries: The maximum number of log entries to keep. Defaults to 10000.
        ///   - logRotationInterval: The interval for log rotation. Defaults to 24 hours.
        ///   - activeTimeRange: The daily time range for active logging. Defaults to nil (always active).
        public init(
            minimumLogLevel: LogLevel = .debug,
            maxLogEntries: Int = 10000,
            logRotationInterval: TimeInterval = 86400,
            activeTimeRange: ClosedRange<Date>? = nil
        ) {
            self.minimumLogLevel = minimumLogLevel
            self.maxLogEntries = maxLogEntries
            self.logRotationInterval = logRotationInterval
            self.activeTimeRange = activeTimeRange
        }
    }
    
    /// The main class responsible for managing log entries and handling logging operations.
    public class Logger: ObservableObject {
        /// The collection of log entries managed by this logger.
        @Published private(set) public var logs: [LogEntry] = []
        private let container: NSPersistentContainer
        private let configuration: LoggerConfiguration
        private var logBuffer: [LogEntry] = []
        private let bufferLimit = 50
        private var lastRotationDate: Date
        private var timer: Timer?
        
        private let queue = DispatchQueue(label: "com.echo.queue", attributes: .concurrent)
        
        /// Initializes a new Logger instance with the given configuration.
        ///
        /// - Parameter configuration: The configuration to use for this logger. Defaults to a standard configuration.
        public init(configuration: LoggerConfiguration = LoggerConfiguration()) {
            self.configuration = configuration
            self.lastRotationDate = Date()
            
            // Create Core Data model programmatically
            let model = NSManagedObjectModel()
            let logEntryEntity = NSEntityDescription()
            logEntryEntity.name = "LogEntryMO"
            logEntryEntity.managedObjectClassName = NSStringFromClass(LogEntryMO.self)
            
            let idAttribute = NSAttributeDescription()
            idAttribute.name = "id"
            idAttribute.attributeType = .UUIDAttributeType
            idAttribute.isOptional = false
            
            let timestampAttribute = NSAttributeDescription()
            timestampAttribute.name = "timestamp"
            timestampAttribute.attributeType = .dateAttributeType
            timestampAttribute.isOptional = false
            
            let levelAttribute = NSAttributeDescription()
            levelAttribute.name = "level"
            levelAttribute.attributeType = .stringAttributeType
            levelAttribute.isOptional = false
            
            let categoryAttribute = NSAttributeDescription()
            categoryAttribute.name = "category"
            categoryAttribute.attributeType = .stringAttributeType
            categoryAttribute.isOptional = false
            
            let messageAttribute = NSAttributeDescription()
            messageAttribute.name = "message"
            messageAttribute.attributeType = .stringAttributeType
            messageAttribute.isOptional = false
            
            let fileNameAttribute = NSAttributeDescription()
            fileNameAttribute.name = "fileName"
            fileNameAttribute.attributeType = .stringAttributeType
            fileNameAttribute.isOptional = false
            
            let functionNameAttribute = NSAttributeDescription()
            functionNameAttribute.name = "functionName"
            functionNameAttribute.attributeType = .stringAttributeType
            functionNameAttribute.isOptional = false
            
            let lineNumberAttribute = NSAttributeDescription()
            lineNumberAttribute.name = "lineNumber"
            lineNumberAttribute.attributeType = .integer64AttributeType
            lineNumberAttribute.isOptional = false
            
            logEntryEntity.properties = [idAttribute, timestampAttribute, levelAttribute, categoryAttribute, messageAttribute, fileNameAttribute, functionNameAttribute, lineNumberAttribute]
            model.entities = [logEntryEntity]
            
            self.container = NSPersistentContainer(name: "EchoDataModel", managedObjectModel: model)
            
            container.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
            
            loadLogsFromCoreData()
            setupTimer()
            setupNotifications()
        }
        
        /// Logs a new entry with the specified parameters.
        ///
        /// - Parameters:
        ///   - level: The severity level of the log entry.
        ///   - category: The category of the log entry. Defaults to .uncategorized.
        ///   - message: The message to be logged.
        ///   - fileName: The name of the file where the log was created. Defaults to the current file.
        ///   - functionName: The name of the function where the log was created. Defaults to the current function.
        ///   - lineNumber: The line number where the log was created. Defaults to the current line number.
        ///   - networkDetails: Additional network-related details for network log entries.
        public func log(
            _ level: LogLevel,
            category: LogCategory = .uncategorized,
            message: String,
            fileName: String = #file,
            functionName: String = #function,
            lineNumber: Int = #line,
            networkDetails: NetworkLogDetails? = nil
        ) {
            guard level >= configuration.minimumLogLevel else { return }
            
            if let activeTimeRange = configuration.activeTimeRange {
                let now = Date()
                guard activeTimeRange.contains(now) else { return }
            }
            
            let shortFileName = URL(fileURLWithPath: fileName).lastPathComponent
            let entry = LogEntry(level: level, category: category, message: message, fileName: shortFileName, functionName: functionName, lineNumber: lineNumber, networkDetails: networkDetails)
            
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.logBuffer.append(entry)
                DispatchQueue.main.async {
                    self.logs.append(entry)
                }
                if self.logBuffer.count >= self.bufferLimit {
                    // Cap logs to maxLogEntries - ensure we don't try to remove negative elements
                    if self.logs.count > self.configuration.maxLogEntries {
                        let elementsToRemove = self.logs.count - self.configuration.maxLogEntries
                        self.logs.removeFirst(elementsToRemove)
                    }
                    self.flushBuffer()
                }
            }

            debugPrint("Log created: \(level) - \(category.name) - \(message)")
        }
        
        /// Exports all logs as a formatted string.
        ///
        /// - Returns: A string containing all log entries, formatted for easy reading.
        public func exportLogs() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            
            return logs.map { log in
                let timestamp = dateFormatter.string(from: log.timestamp)
                return "[\(timestamp)] [\(log.level.rawValue)] [\(log.category.name)] \(log.message) - \(log.fileName):\(log.functionName):\(log.lineNumber)"
            }.joined(separator: "\n")
        }
        
        /// Clears all stored logs.
        public func clearLogs() {
            queue.async(flags: .barrier) { [weak self] in
                DispatchQueue.main.async {
                    self?.logs.removeAll()
                }
                self?.clearLogsFromCoreData()
            }
        }
        
        /// Flushes the log buffer, saving buffered logs to persistent storage.
        public func flushBuffer() {
            debugPrint("Performing buffer flush..")
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                let entriesToSave = self.logBuffer
                self.logBuffer.removeAll()
                
                DispatchQueue.main.async {
                    self.saveToCoreData(entriesToSave)
                    self.rotateLogsIfNeeded()
                }
            }
        }
        
        /// Enables network logging.
        public func enableNetworkLogging() {
            Echo.LoggingURLProtocol.logger = self
            URLProtocol.registerClass(Echo.LoggingURLProtocol.self)
        }
        
        /// Disables network logging.
        public func disableNetworkLogging() {
            Echo.LoggingURLProtocol.logger = nil
            URLProtocol.unregisterClass(Echo.LoggingURLProtocol.self)
        }
        
        // MARK: - Private Methods
        
        private func setupTimer() {
            DispatchQueue.main.async { [weak self] in
                self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                    self?.checkActiveTimeAndRotate()
                }
            }
        }
        
        private func setupNotifications() {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        }
        
        @objc private func applicationWillTerminate() {
            flushBuffer()
            DispatchQueue.main.async { [weak self] in
                self?.saveToCoreData(self?.logs ?? [])
            }
        }
        
        private func checkActiveTimeAndRotate() {
            guard let activeTimeRange = configuration.activeTimeRange else { return }
            
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            let activeStart = calendar.date(byAdding: .second, value: Int(activeTimeRange.lowerBound.timeIntervalSince(startOfDay)), to: startOfDay)!
            let activeEnd = calendar.date(byAdding: .second, value: Int(activeTimeRange.upperBound.timeIntervalSince(startOfDay)), to: startOfDay)!
            
            if now >= activeEnd || now < activeStart {
                performLogRotation()
            }
        }
        
        private func loadLogsFromCoreData() {
            let request: NSFetchRequest<LogEntryMO> = LogEntryMO.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \LogEntryMO.timestamp, ascending: false)]
            request.fetchLimit = configuration.maxLogEntries
            
            do {
                let results = try container.viewContext.fetch(request)
                DispatchQueue.main.async {
                    var loadedLogs: [LogEntry] = results.compactMap { mo in
                        guard let id = mo.id,
                              let timestamp = mo.timestamp,
                              let level = LogLevel(rawValue: mo.level ?? ""),
                              let category = mo.category,
                              let message = mo.message,
                              let fileName = mo.fileName,
                              let functionName = mo.functionName else {
                            return nil
                        }
                        return LogEntry(id: id, timestamp: timestamp, level: level, category: LogCategory(category), message: message, fileName: fileName, functionName: functionName, lineNumber: Int(mo.lineNumber))
                    }

                    DispatchQueue.main.async { [weak self] in
                                   self?.logs = loadedLogs
                               }
                }
                debugPrint("Loaded \(self.logs.count) logs from Core Data")
            } catch {
                debugPrint("Failed to fetch logs: \(error)")
            }
        }
        
        private func saveToCoreData(_ entries: [LogEntry]) {
            let context = container.viewContext
            
            for entry in entries {
                let fetchRequest: NSFetchRequest<LogEntryMO> = LogEntryMO.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
                
                do {
                    let existingEntries = try context.fetch(fetchRequest)
                    if let existingEntry = existingEntries.first {
                        // Update existing entry
                        existingEntry.timestamp = entry.timestamp
                        existingEntry.level = entry.level.rawValue
                        existingEntry.category = entry.category.name
                        existingEntry.message = entry.message
                        existingEntry.fileName = entry.fileName
                        existingEntry.functionName = entry.functionName
                        existingEntry.lineNumber = Int64(entry.lineNumber)
                    } else {
                        // Create new entry
                        let logEntryMO = LogEntryMO(context: context)
                        logEntryMO.id = entry.id
                        logEntryMO.timestamp = entry.timestamp
                        logEntryMO.level = entry.level.rawValue
                        logEntryMO.category = entry.category.name
                        logEntryMO.message = entry.message
                        logEntryMO.fileName = entry.fileName
                        logEntryMO.functionName = entry.functionName
                        logEntryMO.lineNumber = Int64(entry.lineNumber)
                    }
                } catch {
                    debugPrint("Error fetching log entry: \(error)")
                }
            }
            
            do {
                try context.save()
                debugPrint("Saved \(entries.count) logs to Core Data")
            } catch {
                debugPrint("Failed to save log entries: \(error)")
            }
        }
        
        private func clearLogsFromCoreData() {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = LogEntryMO.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try container.viewContext.execute(batchDeleteRequest)
            } catch {
                debugPrint("Failed to clear logs: \(error)")
            }
        }
        
        private func rotateLogsIfNeeded() {
            let currentDate = Date()
            if currentDate.timeIntervalSince(lastRotationDate) >= configuration.logRotationInterval {
                performLogRotation()
                lastRotationDate = currentDate
            }

            // Ensure we only try to trim when we actually exceed the limit
            if logs.count > configuration.maxLogEntries {
                let elementsToRemove = logs.count - configuration.maxLogEntries
                let excessLogs = Array(logs.prefix(elementsToRemove))
                logs.removeFirst(elementsToRemove)
                archiveLogs(excessLogs)
            }
        }

        private func performLogRotation() {
            debugPrint("Performing logs rotation to archiveLogs ..")
            let oldLogs = logs
            DispatchQueue.main.async { [weak self] in
                self?.logs.removeAll()
            }
            archiveLogs(oldLogs)
            clearLogsFromCoreData()
        }
        
        private func archiveLogs(_ logsToArchive: [LogEntry]) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(logsToArchive) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let dateString = dateFormatter.string(from: Date())
                let archivePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("archived_logs_\(dateString).json")
                do {
                    try data.write(to: archivePath)
                    debugPrint("Archived logs successfully to: \(archivePath)")
                } catch {
                    debugPrint("Failed to archive logs: \(error)")
                }
            }
        }
    }
    
    // MARK: - Network Logging
    
    /// Configures what network-related information to log
    public struct NetworkLogOptions: OptionSet, Hashable {
        public let rawValue: Int
        
        public static let url = NetworkLogOptions(rawValue: 1 << 0)
        public static let method = NetworkLogOptions(rawValue: 1 << 1)
        public static let headers = NetworkLogOptions(rawValue: 1 << 2)
        public static let requestBody = NetworkLogOptions(rawValue: 1 << 3)
        public static let responseStatus = NetworkLogOptions(rawValue: 1 << 4)
        public static let responseBody = NetworkLogOptions(rawValue: 1 << 5)
        
        public static let all: NetworkLogOptions = [.url, .method, .headers, .requestBody, .responseStatus, .responseBody]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    /// A custom URLProtocol to intercept and log network requests
    class LoggingURLProtocol: URLProtocol {
        static var logger: Logger?
        static var logOptions: NetworkLogOptions = .all
        
        private lazy var session: URLSession = {
            let config = URLSessionConfiguration.default
            return URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }()
        
        private var dataTask: URLSessionDataTask?
        private var responseData: Data = Data()
        private var requestStartTime: Date?
        private var responseStartTime: Date?
        private var response: URLResponse?
        
        public override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        public override func startLoading() {
            responseData = Data()
            requestStartTime = Date()
            dataTask = session.dataTask(with: request)
            dataTask?.resume()
        }
        
        public override func stopLoading() {
            dataTask?.cancel()
        }
        
        @MainActor
        private func logNetworkActivity(error: Error? = nil) {
            guard let logger = Echo.LoggingURLProtocol.logger else { return }
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            
            let networkDetails = Echo.NetworkLogDetails(
                url: request.url?.absoluteString ?? "",
                method: request.httpMethod ?? "",
                requestHeaders: request.allHTTPHeaderFields ?? [:],
                requestBody: request.httpBody.flatMap { String(data: $0, encoding: .utf8) },
                responseStatus: statusCode,
                responseHeaders: httpResponse?.allHeaderFields as? [String: String] ?? [:],
                responseBody: String(data: responseData, encoding: .utf8)
            )
            
            let duration = responseStartTime?.timeIntervalSince(requestStartTime ?? Date()) ?? 0
            let logLevel: Echo.LogLevel = error != nil ? .error : (200...299).contains(statusCode) ? .info : .warning
            
            var message = "Network Request: \(request.httpMethod ?? "Unknown") \(request.url?.absoluteString ?? "")\n"
            message += "Status: \(statusCode)\n"
            message += "Duration: \(String(format: "%.2f", duration))s\n"
            if let error = error {
                message += "Error: \(error.localizedDescription)\n"
            }
            
            logger.log(
                logLevel,
                category: .network,
                message: message,
                networkDetails: networkDetails
            )
        }
    }
    
    /// Creates a URLSessionConfiguration that includes the LoggingURLProtocol
    ///
    /// - Returns: A URLSessionConfiguration object configured to use LoggingURLProtocol
    public static func urlSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [LoggingURLProtocol.self] + (config.protocolClasses ?? [])
        return config
    }
}

extension Echo.LoggingURLProtocol: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.response = response
        self.responseStartTime = Date()
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.client?.urlProtocol(self, didLoad: data)
        self.responseData.append(data)
    }
    
    @MainActor
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.client?.urlProtocol(self, didFailWithError: error)
        } else {
            self.client?.urlProtocolDidFinishLoading(self)
        }
        logNetworkActivity(error: error)
    }
}

// MARK: - Core Data Managed Object

@objc(LogEntryMO)
public class LogEntryMO: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var level: String?
    @NSManaged public var category: String?
    @NSManaged public var message: String?
    @NSManaged public var fileName: String?
    @NSManaged public var functionName: String?
    @NSManaged public var lineNumber: Int64
}

extension LogEntryMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogEntryMO> {
        return NSFetchRequest<LogEntryMO>(entityName: "LogEntryMO")
    }
}
