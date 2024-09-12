//
//  LogViewer.swift
//  Echo
//
//  Created by Ghazi Tozri on 03/09/2024.

import SwiftUI
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct LogViewer: View {
    @EnvironmentObject private var logger: Echo.Logger
    @State private var searchText = ""
    @State private var selectedLogLevels: Set<Echo.LogLevel> = Set(Echo.LogLevel.allCases)
    @State private var sortOrder: SortOrder = .descending
    @State private var sortCriterion: SortCriterion = .timestamp
    @State private var isFilterSheetPresented = false
    @State private var dateRange: ClosedRange<Date>?
    @State private var isExportPresented = false
    @State private var selectedLogCategories: Set<Echo.LogCategory> = []

    public enum SortOrder: String, CaseIterable {
        case ascending, descending
    }

    public enum SortCriterion: String, CaseIterable {
        case timestamp = "Time"
        case level = "Level"
        case category = "Category"
    }

    private var filteredAndSortedLogs: [Echo.LogEntry] {
        let filtered = logger.logs.filter { log in
            (selectedLogLevels.contains(log.level)) &&
            (selectedLogCategories.isEmpty || selectedLogCategories.contains(log.category)) &&
            (searchText.isEmpty || log.message.lowercased().contains(searchText.lowercased())) &&
            (dateRange == nil || (dateRange?.contains(log.timestamp) ?? true))
        }

        return filtered.sorted { log1, log2 in
            switch sortCriterion {
            case .timestamp:
                return sortOrder == .ascending ? log1.timestamp < log2.timestamp : log1.timestamp > log2.timestamp
            case .level:
                return sortOrder == .ascending ? log1.level < log2.level : log1.level > log2.level
            case .category:
                return sortOrder == .ascending ? log1.category.name < log2.category.name : log1.category.name > log2.category.name
            }
        }
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar

                if filteredAndSortedLogs.isEmpty {
                    emptyStateView
                } else {
                    logList
                }
            }
            .navigationTitle("Logs")
            .navigationBarItems(leading: filterButton, trailing: HStack { sortButton; exportButton })
            .sheet(isPresented: $isFilterSheetPresented) {
                FilterView(selectedLogLevels: $selectedLogLevels,
                           selectedLogCategories: $selectedLogCategories,
                           dateRange: $dateRange)
            }
#if os(iOS) || os(tvOS)
            .sheet(isPresented: $isExportPresented) {
                ActivityViewController(activityItems: [logger.exportLogs()])
            }
#endif

        }
        .onAppear {
            if selectedLogCategories.isEmpty {
                selectedLogCategories = Set(logger.logs.map { $0.category })
            }
        }
    }

    private var searchBar: some View {
        SearchBar(text: $searchText, placeholder: "Search logs")
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("No logs to display")
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var logList: some View {
        List {
            ForEach(filteredAndSortedLogs) { log in
                NavigationLink(destination: LogDetailView(logEntry: log)) {
                    LogEntryRow(log: log)
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private var filterButton: some View {
        Button("Filter") { isFilterSheetPresented = true }
    }

    private var sortButton: some View {
        Menu {
            Picker("Sort By", selection: $sortCriterion) {
                ForEach(SortCriterion.allCases, id: \.self) { criterion in
                    Text(criterion.rawValue).tag(criterion)
                }
            }
            Picker("Sort Order", selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue.capitalized).tag(order)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    private var exportButton: some View {
        Button(action: { isExportPresented = true }) {
            Image(systemName: "square.and.arrow.up")
        }
    }

    public init() {}
}

@available(iOS 14.0, *)
struct LogEntryRow: View {
    let log: Echo.LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(log.message)
                .font(.subheadline)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(log.category.name)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                Text(log.level.rawValue)
                    .font(.caption2)
                    .padding(4)
                    .background(log.level.color.opacity(0.2))
                    .cornerRadius(4)
                Spacer()
                Text(log.timestamp, style: .time)
                    .font(.caption2)
            }
        }
        .padding(.vertical, 8)
    }
}

@available(iOS 14.0, *)
struct LogDetailView: View {
    let logEntry: Echo.LogEntry

    var body: some View {
        List {
            Section(header: Text("Message")) {
                Text(logEntry.message)
            }

            Section(header: Text("Details")) {
                DetailRow(label: "Level", value: logEntry.level.rawValue)
                DetailRow(label: "Category", value: logEntry.category.name)
                DetailRow(label: "Timestamp", value: formatDate(logEntry.timestamp))
                DetailRow(label: "Session ID", value: logEntry.sessionId)
            }

            Section(header: Text("Source")) {
                DetailRow(label: "File", value: logEntry.fileName)
                DetailRow(label: "Function", value: logEntry.functionName)
                DetailRow(label: "Line", value: String(logEntry.lineNumber))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Log Details")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .lineLimit(1)
        }
    }
}

@available(iOS 14.0, *)
struct FilterView: View {
    @Binding var selectedLogLevels: Set<Echo.LogLevel>
    @Binding var selectedLogCategories: Set<Echo.LogCategory>
    @Binding var dateRange: ClosedRange<Date>?
    @State private var isDateFilterEnabled = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @Environment(\.presentationMode) var presentationMode
    @State private var categorySelections: [Echo.LogCategory: Bool] = [:]

    let allCategories: [Echo.LogCategory] = [
        .uncategorized, .network, .userInterface, .database,
        .authentication, .businessLogic, .performance
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Levels")) {
                    ForEach(Echo.LogLevel.allCases, id: \.self) { level in
                        Toggle(level.rawValue, isOn: Binding(
                            get: { selectedLogLevels.contains(level) },
                            set: { isSelected in
                                if isSelected {
                                    selectedLogLevels.insert(level)
                                } else {
                                    selectedLogLevels.remove(level)
                                }
                            }
                        ))
                    }
                }

                Section(header: Text("Log Categories")) {
                    ForEach(allCategories.sorted(by: { $0.name < $1.name }), id: \.name) { category in
                        Toggle(category.name, isOn: Binding(
                            get: { categorySelections[category] ?? false },
                            set: { isSelected in
                                categorySelections[category] = isSelected
                                updateSelectedCategories()
                            }
                        ))
                    }
                }

                Section(header: Text("Date Range")) {
                    Toggle("Enable Date Filter", isOn: $isDateFilterEnabled)
                    if isDateFilterEnabled {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filter Logs")
            .navigationBarItems(
                leading: Button("Reset") { resetFilters() },
                trailing: Button("Apply") { applyFilters() }
            )
        }
        .onAppear(perform: initializeCategorySelections)
    }

    private func initializeCategorySelections() {
        for category in allCategories {
            categorySelections[category] = selectedLogCategories.contains(category)
        }
        // If no categories are selected, select all by default
        if selectedLogCategories.isEmpty {
            for category in allCategories {
                categorySelections[category] = true
            }
            updateSelectedCategories()
        }
    }

    private func updateSelectedCategories() {
        selectedLogCategories = Set(categorySelections.filter { $0.value }.map { $0.key })
    }

    private func resetFilters() {
        selectedLogLevels = Set(Echo.LogLevel.allCases)
        for category in allCategories {
            categorySelections[category] = true
        }
        updateSelectedCategories()
        isDateFilterEnabled = false
        dateRange = nil
    }

    private func applyFilters() {
        if isDateFilterEnabled {
            dateRange = startDate...endDate
        } else {
            dateRange = nil
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}

#if os(iOS) || os(tvOS)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}
#endif
