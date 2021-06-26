//
//  ViewController.swift
//  iBeaconInfo
//
//  Created by Joshua Vickery on 6/24/21.
//

import UIKit

import CoreBluetooth

class ViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    struct Device {
        var identifier: String
        var name: String
        var rssi: Int
        var readings: [Int]
    }
    
    var btManager: CBCentralManager?;
    var deviceList = [String: Device]()
    var sortedList = [Device]()
    var timeSinceLastRefresh = Date()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        btManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        btManager = nil
    }

    // CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            btManager?.scanForPeripherals(withServices: nil, options:  [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true)])
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let previousReadings = deviceList[peripheral.identifier.uuidString]?.readings ?? [Int]()
        var simpleMovingRSSIAverage = -100
        var newReadings = previousReadings
        let sampleSize = 10
        if previousReadings.count >= sampleSize {
            newReadings.removeSubrange(0..<previousReadings.count - sampleSize)
        }
        newReadings.append(RSSI.intValue)
        simpleMovingRSSIAverage = newReadings.reduce(0, +) / newReadings.count
        let monitoredDevice = Device(identifier: peripheral.identifier.uuidString,
                                     name: peripheral.name ?? "",
                                     rssi: simpleMovingRSSIAverage,
                                     readings: newReadings)
        deviceList[peripheral.identifier.uuidString] = monitoredDevice
        if (newReadings.count == 1) || ((Date().timeIntervalSince1970 - timeSinceLastRefresh.timeIntervalSince1970) > 5) {
            sortedList.removeAll()
            let sortedValues = deviceList.values.sorted(by: {
                $0.rssi > $1.rssi
            })
            sortedList.append(contentsOf: sortedValues)
            timeSinceLastRefresh = Date()
            tableView.reloadData()
        }
    }
    
    // UITableViewController
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
        let device = sortedList[indexPath.row]
        cell.textLabel?.text = String(device.rssi) + " -- " + device.name
        cell.detailTextLabel?.text = device.identifier
        return cell
    }

    
    
}

