import Foundation
import CoreBluetooth
import SwiftUI

@MainActor
final class GlassesViewModel: NSObject, ObservableObject {
    @Published private(set) var logMessages: [String] = ["Ready to work with HeyCyan glasses"]
    @Published private(set) var isScanning = false
    @Published private(set) var isConnected = false
    @Published private(set) var lastVersionSummary = "—"
    @Published private(set) var lastBatterySummary = "—"

    private let maxLogEntries = 50
    private let centralManager = QCCentralManager.shared()
    private let sdkManager = QCSDKManager.shareInstance()
    private var discoveredPeripherals: [QCBlePeripheral] = []

    override init() {
        super.init()
        centralManager.delegate = self
        sdkManager.delegate = self
        log("QCSDK initialized")
    }

    func scanForDevices() {
        discoveredPeripherals.removeAll()
        isScanning = true
        log("Scanning for HeyCyan glasses…")
        centralManager.scan()
    }

    func connectToFirstDevice() {
        guard let firstDevice = discoveredPeripherals.first else {
            log("No peripherals yet. Run scan first.")
            return
        }
        log("Connecting to \(firstDevice.peripheral.name ?? "Unknown device")…")
        centralManager.connect(firstDevice.peripheral, deviceType: QCDeviceType.glasses)
    }

    func fetchVersion() {
        log("Requesting version info…")
        QCSDKCmdCreator.getDeviceVersionInfoSuccess({ [weak self] hd, firmware, hdWiFi, fwWiFi in
            Task { @MainActor in
                let hardware = hd ?? "?"
                let firmware = firmware ?? "?"
                let wifiHw = hdWiFi ?? "?"
                let wifiFw = fwWiFi ?? "?"
                self?.lastVersionSummary = "HW: \(hardware) | FW: \(firmware)"
                self?.log("Version → HW: \(hardware), FW: \(firmware), WiFi HW: \(wifiHw), WiFi FW: \(wifiFw)")
            }
        }, fail: { [weak self] in
            Task { @MainActor in
                self?.log("Version request failed")
            }
        })
    }

    func fetchBattery() {
        log("Requesting battery status…")
        QCSDKCmdCreator.getDeviceBattery({ [weak self] battery, charging in
            Task { @MainActor in
                self?.lastBatterySummary = "\(battery)% \(charging ? "(charging)" : "")"
                self?.log("Battery → \(battery)% \(charging ? "(charging)" : "")")
            }
        }, fail: { [weak self] in
            Task { @MainActor in
                self?.log("Battery request failed")
            }
        })
    }

    func triggerPhotoMode() {
        log("Setting device to photo mode…")
        QCSDKCmdCreator.setDeviceMode(.photo, success: { [weak self] in
            Task { @MainActor in
                self?.log("Photo command sent successfully")
            }
        }, fail: { [weak self] mode in
            Task { @MainActor in
                self?.log("Photo command failed. Current mode: \(mode)")
            }
        })
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false
        log("Stopped scanning")
    }

    private func log(_ message: String) {
        let formatter = Self.timestampFormatter
        let entry = "[\(formatter.string(from: Date()))] \(message)"
        logMessages.append(entry)
        if logMessages.count > maxLogEntries {
            logMessages.removeFirst(logMessages.count - maxLogEntries)
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

// MARK: - QCCentralManagerDelegate
extension GlassesViewModel: QCCentralManagerDelegate {
    nonisolated func didScanPeripherals(_ peripheralArr: [QCBlePeripheral]!) {
        Task { @MainActor in
            self.isScanning = false
            self.discoveredPeripherals = peripheralArr ?? []
            if self.discoveredPeripherals.isEmpty {
                self.log("Scan finished. No devices found yet.")
            } else {
                let names = self.discoveredPeripherals.compactMap { $0.peripheral.name ?? $0.mac }
                self.log("Scan found \(names.count) device(s): \(names.joined(separator: ", "))")
            }
        }
    }

    nonisolated func scanPeripheralFinish() {
        Task { @MainActor in
            self.isScanning = false
            self.log("Scan timeout reached")
        }
    }

    nonisolated func didState(_ state: QCState) {
        Task { @MainActor in
            self.isConnected = (state == .connected)
            self.log("Connection state changed → \(state.rawValue)")
        }
    }

    nonisolated func didConnected(_ peripheral: CBPeripheral!) {
        Task { @MainActor in
            self.isConnected = true
            self.log("Connected to \(peripheral.name ?? "Unknown")")
        }
    }

    nonisolated func didDisconnecte(_ peripheral: CBPeripheral!) {
        Task { @MainActor in
            self.isConnected = false
            self.log("Disconnected from \(peripheral.name ?? "Unknown")")
        }
    }

    nonisolated func didFailConnected(_ peripheral: CBPeripheral!, error: Error!) {
        Task { @MainActor in
            let errorMessage = error?.localizedDescription ?? "Unknown error"
            self.log("Failed to connect to \(peripheral.name ?? "Unknown"): \(errorMessage)")
        }
    }

    nonisolated func didBluetoothState(_ state: QCBluetoothState) {
        Task { @MainActor in
            self.log("Bluetooth state → \(state.rawValue)")
        }
    }
}

// MARK: - QCSDKManagerDelegate
extension GlassesViewModel: QCSDKManagerDelegate {
    nonisolated func didUpdateBatteryLevel(_ battery: Int, charging: Bool) {
        Task { @MainActor in
            self.lastBatterySummary = "\(battery)% \(charging ? "(charging)" : "")"
            self.log("Battery update → \(battery)% \(charging ? "(charging)" : "")")
        }
    }

    nonisolated func didUpdateMedia(withPhotoCount photo: Int, videoCount video: Int, audioCount audio: Int, type: Int) {
        Task { @MainActor in
            self.log("Media counts → photo: \(photo), video: \(video), audio: \(audio)")
        }
    }
}
