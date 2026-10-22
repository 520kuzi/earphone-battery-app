import Foundation
import CoreBluetooth
import Combine

public struct UsageSession: Identifiable, Codable {
    public var id = UUID()
    public let startTime: Date
    public var endTime: Date?
    public let startBattery: Int
    public var endBattery: Int?
    
    public var durationMinutes: Int {
        guard let end = endTime else { return 0 }
        return Int(end.timeIntervalSince(startTime) / 60)
    }
    
    public var consumedBattery: Int {
        guard let end = endBattery else { return 0 }
        return max(0, startBattery - end)
    }
}

public class BatteryManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published public var isConnected = false
    @Published public var currentBattery: Int = -1
    @Published public var sessions: [UsageSession] = []
    @Published public var activeSession: UsageSession?
    
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    
    private let batteryServiceUUID = CBUUID(string: "180F")
    private let batteryLevelCharUUID = CBUUID(string: "2A19")
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func startScan() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [batteryServiceUUID], options: nil)
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.targetPeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([batteryServiceUUID])
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        if var session = activeSession {
            session.endTime = Date()
            session.endBattery = currentBattery
            sessions.insert(session, at: 0)
            activeSession = nil
        }
        startScan()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == batteryServiceUUID {
            peripheral.discoverCharacteristics([batteryLevelCharUUID], for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics where char.uuid == batteryLevelCharUUID {
            peripheral.readValue(for: char)
            peripheral.setNotifyValue(true, for: char)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == batteryLevelCharUUID, let data = characteristic.value, let firstByte = data.first {
            let battery = Int(firstByte)
            DispatchQueue.main.async {
                self.currentBattery = battery
                if self.activeSession == nil {
                    self.activeSession = UsageSession(startTime: Date(), startBattery: battery)
                }
            }
        }
    }
}