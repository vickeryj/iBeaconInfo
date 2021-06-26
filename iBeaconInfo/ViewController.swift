//
//  ViewController.swift
//  iBeaconInfo
//
//  Created by Joshua Vickery on 6/24/21.
//

import UIKit

import CoreBluetooth

class ViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var btManager: CBCentralManager?;
    var deviceList = [String: [String: String]]()
    var sortedList = [[String: String]]()
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
        let numberOfReadings = Int(deviceList[peripheral.identifier.uuidString]?["numberOfReadings"] ?? "") ?? 0
        var movingRSSIAverage : Int = 0
        if let rssi = Int(deviceList[peripheral.identifier.uuidString]?["rssi"] ?? "") {
            movingRSSIAverage = ((rssi * numberOfReadings) + RSSI.intValue) / (numberOfReadings + 1)
        } else {
            movingRSSIAverage = Int(truncating: RSSI )
        }
        deviceList[peripheral.identifier.uuidString] = ["identifier": peripheral.identifier.uuidString,
                                                        "name": peripheral.name ?? "",
                                                        "rssi": String(describing: movingRSSIAverage),
                                                        "numberOfReadings": String(describing: numberOfReadings + 1)]
        if (numberOfReadings == 0) || ((Date().timeIntervalSince1970 - timeSinceLastRefresh.timeIntervalSince1970) > 5) {
            sortedList.removeAll()
            let sortedValues = deviceList.values.sorted(by: {
                Int($0["rssi"] ?? "") ?? 0 > Int($1["rssi"] ?? "") ?? 0
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
        cell.textLabel?.text = (device["rssi"] ?? "") + " -- " + (device["name"] ?? "")
        cell.detailTextLabel?.text = device["identifier"]
        return cell
    }

    
    
}

