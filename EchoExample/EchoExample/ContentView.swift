import SwiftUI
import Echo

@available(iOS 14.0, *)
struct ContentView: View {
    @StateObject private var logger = Echo.Logger(configuration: Echo.LoggerConfiguration(
        minimumLogLevel: .debug,
        maxLogEntries: 1000,
        logRotationInterval: 30 // 30 seconds for demo purposes, typically this would be longer
    ))
    @State private var isLoading = false
    @State private var showLogViewer = false
    @State private var isNetworkLoggingEnabled = true
    @State private var networkLogOptions: Echo.NetworkLogOptions = .all

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Echo Logger Demo")
                        .font(.largeTitle)
                        .padding(.top)

                    Text("Current Log Count: \(logger.logs.count)")
                        .font(.headline)

                    Group {
                        logButton(level: .debug, category: .userInterface, message: "Debug UI message")
                        logButton(level: .info, category: .network, message: "Info network message")
                        logButton(level: .warning, category: .database, message: "Warning database message")
                        logButton(level: .error, category: .authentication, message: "Error auth message")
                        logButton(level: .critical, category: .businessLogic, message: "Critical business logic message")
                    }

                    Button("Simulate API Call") {
                        simulateAPICall()
                    }
                    .buttonStyle(FilledButtonStyle())

                    if isLoading {
                        ProgressView()
                    }

                    Button("Show Logs") {
                        showLogViewer = true
                    }
                    .buttonStyle(FilledButtonStyle())

                    Button("Force Save Logs") {
                        logger.flushBuffer()
                    }
                    .buttonStyle(FilledButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Echo Logger Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showLogViewer) {
            LogViewer().environmentObject(logger)
        }
        .onAppear {
            logger.enableNetworkLogging()
            logger.log(.info, category: .lifecycle, message: "ContentView appeared")
        }
    }

    private func logButton(level: Echo.LogLevel, category: Echo.LogCategory, message: String) -> some View {
        Button("Log \(level.rawValue.capitalized) (\(category.name))") {
            logger.log(level, category: category, message: message)
        }
        .buttonStyle(OutlinedButtonStyle())
    }

    private func simulateAPICall() {
        isLoading = true
        logger.log(.info, category: .network, message: "Starting API call to /users")

        let urlString = "https://jsonplaceholder.typicode.com/users/1"
        guard let url = URL(string: urlString) else {
            logger.log(.error, category: .network, message: "Invalid URL")
            isLoading = false
            return
        }

        let session = URLSession(configuration: Echo.urlSessionConfiguration())
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    logger.log(.error, category: .network, message: "API call failed: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    logger.log(.info, category: .network, message: "API call succeeded with status code: \(httpResponse.statusCode)")
                }
            }
        }
        .resume()
    }
}

struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .foregroundColor(.blue)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
