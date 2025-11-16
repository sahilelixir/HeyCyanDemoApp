import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GlassesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                statusView
                actionButtons
                logView
            }
            .padding()
            .navigationTitle("HeyCyan Demo")
        }
    }

    private var statusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.isConnected ? "Connected" : "Disconnected")
                .font(.headline)
                .foregroundStyle(viewModel.isConnected ? .green : .secondary)
            Text("Version: \(viewModel.lastVersionSummary)")
                .font(.subheadline)
            Text("Battery: \(viewModel.lastBatterySummary)")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.scanForDevices) {
                Label(viewModel.isScanning ? "Scanning…" : "Scan for devices", systemImage: "wave.3.right")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isScanning)

            Button(action: viewModel.connectToFirstDevice) {
                Label("Connect to first device", systemImage: "dot.radiowaves.up.forward")
            }
            .buttonStyle(.bordered)

            Button(action: viewModel.fetchVersion) {
                Label("Get device version", systemImage: "info.circle")
            }
            .buttonStyle(.bordered)

            Button(action: viewModel.fetchBattery) {
                Label("Get battery level", systemImage: "bolt.fill")
            }
            .buttonStyle(.bordered)

            Button(action: viewModel.triggerPhotoMode) {
                Label("Set photo mode", systemImage: "camera")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
    }

    private var logView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log")
                .font(.headline)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(viewModel.logMessages.enumerated()), id: \.offset) { _, message in
                        Text(message)
                            .font(.caption)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .monospaced()
                            .padding(.vertical, 2)
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ContentView()
}
