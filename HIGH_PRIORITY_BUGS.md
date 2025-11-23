# High Priority Bugs - Echo Logging System

**Analysis Date:** 2025-11-23
**Analyzed Files:**
- Sources/Echo/Echo.swift
- Sources/Echo/LogViewer.swift
- Sources/Echo/Modifiers.swift
- Tests/EchoTests/EchoTests.swift

## Executive Summary

Identified **12 high-priority bugs** in the Echo logging system, including:
- **4 CRITICAL** bugs that can cause crashes, data corruption, or severe performance issues
- **6 HIGH** priority bugs affecting stability, memory management, and functionality
- **2 MEDIUM** priority bugs requiring attention

---

## 🚨 CRITICAL Priority Bugs

### Bug #1: Fatal Error on Core Data Load Failure
**Severity:** CRITICAL - App Crash
**File:** `Sources/Echo/Echo.swift:281-285`
**Component:** Logger initialization

**Description:**
```swift
container.loadPersistentStores { (storeDescription, error) in
    if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
    }
}
```

**Problem:** Uses `fatalError()` when Core Data store fails to load, causing immediate app termination.

**Impact:** Any Core Data initialization issue (disk full, permissions, corruption) crashes the entire app. This is unacceptable for a logging library which should be resilient.

**Fix Required:**
- Implement graceful error handling
- Fall back to in-memory storage if persistent store fails
- Log error but don't crash the app
- Provide callback to notify app of initialization failure

---

### Bug #2: Thread Safety - Race Condition in Log Buffer
**Severity:** CRITICAL - Data Corruption
**File:** `Sources/Echo/Echo.swift:321-335`
**Component:** Log method

**Description:**
```swift
queue.async(flags: .barrier) { [weak self] in
    guard let self = self else { return }
    self.logBuffer.append(entry)
    DispatchQueue.main.async {
        self.logs.append(entry)  // Line 325
    }
    if self.logBuffer.count >= self.bufferLimit {
        if self.logs.count > self.configuration.maxLogEntries {  // Line 329
            let elementsToRemove = self.logs.count - self.configuration.maxLogEntries
            self.logs.removeFirst(elementsToRemove)  // Line 331
        }
        self.flushBuffer()
    }
}
```

**Problem:**
- `logs` array is modified on main queue (line 325) asynchronously
- `logs.count` is checked and array is modified from barrier queue (lines 329-331)
- No synchronization between these accesses
- Classic race condition

**Impact:**
- Array index out of bounds crashes
- Data corruption
- Inconsistent log counts
- Can manifest intermittently under high load

**Fix Required:**
- Synchronize all `logs` array access on a single queue
- Either keep `logs` modifications on barrier queue or move count check to main queue
- Use proper synchronization primitives

---

### Bug #3: Main Thread Blocking - Inefficient Core Data Operations
**Severity:** CRITICAL - Performance
**File:** `Sources/Echo/Echo.swift:457-498`
**Component:** saveToCoreData method

**Description:**
```swift
private func saveToCoreData(_ entries: [LogEntry]) {
    let context = container.viewContext  // Main thread context!

    for entry in entries {  // O(n) loop
        let fetchRequest: NSFetchRequest<LogEntryMO> = LogEntryMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)

        do {
            let existingEntries = try context.fetch(fetchRequest)  // Individual fetch!
            if let existingEntry = existingEntries.first {
                // Update existing entry
            } else {
                // Create new entry
            }
        } catch {
            debugPrint("Error fetching log entry: \(error)")
        }
    }

    do {
        try context.save()  // Save all at end
    }
}
```

**Problem:**
- Performs individual fetch for each of 50 log entries when buffer flushes
- Uses `viewContext` which operates on main thread
- Called from `flushBuffer()` on main thread (line 372)
- 50 individual Core Data fetches + 1 save on main thread

**Impact:**
- UI freezes every time buffer flushes (every 50 log entries)
- Severe performance degradation
- Poor user experience
- Can cause ANR (Application Not Responding) warnings

**Fix Required:**
- Batch fetch all entries in single query using IN predicate
- Use background context instead of viewContext
- Perform operations on background queue
- Consider using batch insert operations

---

### Bug #4: @MainActor Thread Safety Violation
**Severity:** CRITICAL - Thread Safety
**File:** `Sources/Echo/Echo.swift:610-611, 669-676`
**Component:** LoggingURLProtocol

**Description:**
```swift
@MainActor
private func logNetworkActivity(error: Error? = nil) {
    guard let logger = Echo.LoggingURLProtocol.logger else { return }
    // ... network logging logic
}

@MainActor
public func urlSession(_ session: URLSession, task: URLSessionTask,
                       didCompleteWithError error: Error?) {
    if let error = error {
        self.client?.urlProtocol(self, didFailWithError: error)
    } else {
        self.client?.urlProtocolDidFinishLoading(self)
    }
    logNetworkActivity(error: error)  // Called from background queue!
}
```

**Problem:**
- Methods marked `@MainActor` but called from URLSession delegate callbacks
- URLSession delegates run on background queue (configured at line 582)
- Violates Swift concurrency guarantees

**Impact:**
- Runtime warnings in Swift 5.5+
- Potential crashes in Swift 6 with strict concurrency checking
- Data races accessing main-thread-only properties
- Undefined behavior

**Fix Required:**
- Remove `@MainActor` annotation
- Explicitly dispatch to main thread if needed: `Task { @MainActor in ... }`
- Or restructure to not require main thread access

---

## ⚠️ HIGH Priority Bugs

### Bug #5: Force Unwrap in Critical Path
**Severity:** HIGH - Potential Crash
**File:** `Sources/Echo/Echo.swift:61`
**Component:** LogLevel comparison operator

**Description:**
```swift
public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    let order: [LogLevel] = [.debug, .info, .warning, .error, .critical]
    return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
}
```

**Problem:** Force unwraps in comparison operator. If enum is extended without updating this array, crash.

**Impact:**
- Crashes if LogLevel enum is extended
- Hard to debug - crash in comparison operator
- Violates Swift safety principles

**Fix Required:**
```swift
public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    let order: [LogLevel] = [.debug, .info, .warning, .error, .critical]
    guard let lhsIndex = order.firstIndex(of: lhs),
          let rhsIndex = order.firstIndex(of: rhs) else {
        return false  // Or handle appropriately
    }
    return lhsIndex < rhsIndex
}
```

---

### Bug #6: Memory Leak - Timer Never Invalidated
**Severity:** HIGH - Memory Leak
**File:** `Sources/Echo/Echo.swift:219, 392-397`
**Component:** Logger class

**Description:**
```swift
private var timer: Timer?

private func setupTimer() {
    DispatchQueue.main.async { [weak self] in
        self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) {
            [weak self] _ in
            self?.checkActiveTimeAndRotate()
        }
    }
}
// NO deinit method to clean up!
```

**Problem:**
- Timer is created and scheduled but never invalidated
- Even with weak self, Timer keeps strong reference to target
- No `deinit` to clean up resources

**Impact:**
- Logger instances never deallocated
- Memory leak grows with each Logger instance
- Timer continues firing even when Logger should be deallocated
- Wasted CPU cycles

**Fix Required:**
```swift
deinit {
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

---

### Bug #7: Infinite Loop Risk - URLProtocol Intercepts ALL Requests
**Severity:** HIGH - Performance/Infinite Loop
**File:** `Sources/Echo/Echo.swift:591-593`
**Component:** LoggingURLProtocol

**Description:**
```swift
public override class func canInit(with request: URLRequest) -> Bool {
    return true  // Intercepts EVERY request!
}
```

**Problem:**
- Intercepts ALL network requests without filtering
- If logging system makes network requests (analytics, crash reporting), infinite recursion
- No opt-out mechanism
- Unnecessary overhead for non-logged requests

**Impact:**
- Performance degradation (every request goes through protocol)
- Risk of infinite recursion
- Can't exclude internal/system requests
- May interfere with other URLProtocol implementations

**Fix Required:**
```swift
private static let echoProtocolHandledKey = "EchoProtocolHandled"

public override class func canInit(with request: URLRequest) -> Bool {
    // Don't handle if already handled
    if URLProtocol.property(forKey: echoProtocolHandledKey, in: request) != nil {
        return false
    }

    // Add filters for specific hosts/schemes if needed
    guard let url = request.url else { return false }

    // Example: Don't log localhost or internal requests
    if url.host?.contains("localhost") == true {
        return false
    }

    return true
}

public override func startLoading() {
    let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
    URLProtocol.setProperty(true, forKey: Self.echoProtocolHandledKey,
                           in: mutableRequest)
    // ... rest of implementation
}
```

---

### Bug #8: Incorrect Time Range Logic
**Severity:** HIGH - Logic Error
**File:** `Sources/Echo/Echo.swift:313-316`
**Component:** Log method time range check

**Description:**
```swift
if let activeTimeRange = configuration.activeTimeRange {
    let now = Date()
    guard activeTimeRange.contains(now) else { return }
}
```

**Problem:**
- Compares full `Date` objects (including date portion)
- `activeTimeRange` type is `ClosedRange<Date>?`
- Method `checkActiveTimeAndRotate` (lines 414-423) suggests time-of-day logic
- Current implementation requires exact date match, not time-of-day

**Impact:**
- Active time range feature doesn't work as intended
- Logs only during specific date range, not daily time range
- Confusing API - parameter name suggests time-of-day but accepts full dates

**Fix Required:**
- Change configuration to use time components or DateComponents
- Extract time-of-day from current date and compare
- Document expected behavior clearly

---

### Bug #9: Nested Main Queue Dispatch
**Severity:** HIGH - Logic Error
**File:** `Sources/Echo/Echo.swift:433-451`
**Component:** loadLogsFromCoreData method

**Description:**
```swift
do {
    let results = try container.viewContext.fetch(request)
    DispatchQueue.main.async {  // First dispatch
        var loadedLogs: [LogEntry] = results.compactMap { /* ... */ }

        DispatchQueue.main.async { [weak self] in  // NESTED dispatch!
            self?.logs = loadedLogs
        }
    }
    debugPrint("Loaded \(self.logs.count) logs from Core Data")  // Wrong!
} catch {
    debugPrint("Failed to fetch logs: \(error)")
}
```

**Problem:**
1. Nested `DispatchQueue.main.async` when already dispatched to main
2. Line 451 prints `self.logs.count` before logs are actually assigned (async)
3. Unnecessary dispatch overhead

**Impact:**
- Incorrect debug output (prints old count)
- Unnecessary performance overhead
- Confusing code flow

**Fix Required:**
```swift
do {
    let results = try container.viewContext.fetch(request)
    let loadedLogs: [LogEntry] = results.compactMap { /* ... */ }

    DispatchQueue.main.async { [weak self] in
        self?.logs = loadedLogs
        debugPrint("Loaded \(loadedLogs.count) logs from Core Data")
    }
} catch {
    debugPrint("Failed to fetch logs: \(error)")
}
```

---

### Bug #10: Production Debug Statements
**Severity:** MEDIUM-HIGH - Performance/Security
**Files:** Multiple locations in `Sources/Echo/Echo.swift`
**Lines:** 337, 365, 451, 453, 494, 496, 507, 528, 547, 549

**Description:**
Multiple `debugPrint` statements throughout production code:
```swift
debugPrint("Log created: \(level) - \(category.name) - \(message)")
debugPrint("Performing buffer flush..")
debugPrint("Loaded \(self.logs.count) logs from Core Data")
debugPrint("Failed to fetch logs: \(error)")
debugPrint("Saved \(entries.count) logs to Core Data")
// ... and more
```

**Problem:**
- Debug statements in production code
- Always executed, not conditional
- Can expose sensitive information
- Performance overhead (string interpolation)
- Console spam

**Impact:**
- Performance degradation (especially line 337 called for every log)
- Information leakage in production logs
- Difficult to debug with console spam
- Unprofessional output

**Fix Required:**
```swift
#if DEBUG
debugPrint("Log created: \(level) - \(category.name) - \(message)")
#endif
```
Or remove entirely and use proper logging levels.

---

## 📊 MEDIUM Priority Bugs

### Bug #11: NotificationCenter Observer Not Removed
**Severity:** MEDIUM - Potential Leak
**File:** `Sources/Echo/Echo.swift:401`
**Component:** setupNotifications method

**Description:**
```swift
private func setupNotifications() {
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationWillTerminate),
        name: UIApplication.willTerminateNotification,
        object: nil
    )
}
// No removal in deinit
```

**Problem:** Observer added but never explicitly removed.

**Impact:**
- Modern iOS handles this automatically for most cases
- Edge cases may still cause issues
- Best practice violation
- Combines with Bug #6 for memory management issues

**Fix Required:**
Add to deinit (from Bug #6 fix):
```swift
deinit {
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

---

### Bug #12: Timer Closure Retain Cycle Potential
**Severity:** MEDIUM - Potential Leak
**File:** `Sources/Echo/Echo.swift:394`
**Component:** setupTimer method

**Description:**
```swift
self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) {
    [weak self] _ in
    self?.checkActiveTimeAndRotate()
}
```

**Problem:**
- While weak self is used correctly in closure
- Timer itself is never invalidated (Bug #6)
- Timer keeps strong reference to target regardless of weak capture
- Combined effect prevents deallocation

**Impact:** Contributes to memory leak along with Bug #6.

**Fix Required:** Same as Bug #6 - invalidate timer in deinit.

---

## 🧪 Test Coverage Issues

**File:** `Tests/EchoTests/EchoTests.swift`

**Problem:** Test file is essentially empty - only contains placeholder test.

**Impact:**
- No automated testing of critical functionality
- Bugs go undetected until production
- Regression risk when fixing bugs
- No verification of thread safety

**Required Test Coverage:**
1. Logger initialization and configuration
2. Log level filtering
3. Buffer flushing behavior
4. Core Data persistence and retrieval
5. Log rotation logic
6. Network logging interception
7. Thread safety of concurrent logging
8. Memory management (no leaks)
9. Edge cases (buffer overflow, disk full, etc.)

---

## 🎯 Prioritized Fix Recommendations

### Immediate (Fix Before Next Release):
1. **Bug #1** - Fatal error on Core Data failure
2. **Bug #2** - Race condition in log buffer
3. **Bug #3** - Main thread blocking in saveToCoreData
4. **Bug #4** - @MainActor thread safety violations

### High Priority (Fix Soon):
5. **Bug #6** - Add deinit for cleanup
6. **Bug #7** - Filter URLProtocol requests
7. **Bug #5** - Remove force unwraps
8. **Bug #8** - Fix time range logic
9. **Bug #9** - Remove nested dispatch

### Medium Priority (Next Sprint):
10. **Bug #10** - Remove/conditionally compile debug statements
11. **Bug #11** - Remove notification observers
12. **Bug #12** - Ensure timer cleanup
13. **Add comprehensive test coverage**

---

## 📈 Risk Assessment

**Production Readiness:** ⚠️ **NOT READY**

**Blockers:**
- CRITICAL bugs can cause crashes and data corruption
- Thread safety issues violate Swift concurrency
- Performance issues can freeze UI
- Memory leaks will accumulate over time

**Recommendation:** Address all CRITICAL and HIGH priority bugs before production use.

---

## 📝 Additional Recommendations

1. **Add SwiftLint/SwiftFormat** - Enforce code quality standards
2. **Enable Thread Sanitizer** - Detect race conditions in testing
3. **Add Memory Testing** - Use Instruments to verify no leaks
4. **Comprehensive Unit Tests** - Achieve >80% code coverage
5. **Integration Tests** - Test Core Data, threading, network logging
6. **Performance Benchmarks** - Ensure logging doesn't impact app performance
7. **Documentation** - Document thread safety guarantees and limitations

---

**Report Generated:** 2025-11-23
**Analyzer:** Claude Code (Automated Code Analysis)
**Files Analyzed:** 4
**Lines of Code Analyzed:** ~1,138
**Bugs Found:** 12 (4 Critical, 6 High, 2 Medium)
