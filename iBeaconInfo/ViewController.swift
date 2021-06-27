//
//  ViewController.swift
//  iBeaconInfo
//
//  Created by Joshua Vickery on 6/24/21.
//

import UIKit

import CoreLocation

class ViewController: UITableViewController, CLLocationManagerDelegate {
    
    struct Device {
        var identifier: String
        var rssi: Int
        var proximities: [CLProximity]
        var accuracies: [CLLocationAccuracy]
        var proximity: CLProximity
        var accuracy: CLLocationAccuracy
    }
    
    var deviceList = [String: Device]()
    var sortedList = [Device]()
    var timeSinceLastRefresh = Date()
    var locationManager: CLLocationManager?
    let locationUuidString = "b7018592-874a-4934-b463-84555fee0070"
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        if let locationUuid = UUID.init(uuidString: locationUuidString) {
            let constraint = CLBeaconIdentityConstraint(uuid: locationUuid)
            let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "whateven")
            locationManager?.startMonitoring(for: beaconRegion)
        }
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager = nil
    }
    
    // MARK: CLLocationManageDelegate
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .unknown:
            print("unknown")
        case .inside:
            print("inside")
        case .outside:
            print("outside")
        }
        print(state)
        if let locationUuid = UUID.init(uuidString: locationUuidString) {
            locationManager?.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: locationUuid))
        }
    }

    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        for beacon in beacons {
            let majorMinorString = String(format:"%@-%@",beacon.major, beacon.minor)
            let previousProximities = deviceList[majorMinorString]?.proximities ?? [CLProximity]()
            var newProximities = previousProximities
            let previousAccuracies = deviceList[majorMinorString]?.accuracies ?? [CLLocationAccuracy]()
            var newAccuracies = previousAccuracies
            let sampleSize = 10
            if previousProximities.count == sampleSize {
                newProximities.removeSubrange(0..<1)
            }
            if previousAccuracies.count == sampleSize {
                newAccuracies.removeSubrange(0..<1)
            }
            newProximities.append(beacon.proximity)
            newAccuracies.append(beacon.accuracy)
            var proximitiesCounts = [CLProximity: Int]()
            for proximity in newProximities {
                if proximity != .unknown {
                    proximitiesCounts[proximity] = proximitiesCounts[proximity] ?? 0 + 1
                }
            }
            var mostFrequentProximity = beacon.proximity
            for proximity in newProximities {
                if proximitiesCounts[proximity] ?? 0 > proximitiesCounts[mostFrequentProximity] ?? 0 {
                    mostFrequentProximity = proximity
                }
            }
            var accuraciesForMostFrequestProximities = [CLLocationAccuracy]()
            for (index, proximity) in newProximities.enumerated() {
                if proximity == mostFrequentProximity {
                    accuraciesForMostFrequestProximities.append(newAccuracies[index])
                }
            }
            let simpleMovingAccuraciesAverage = accuraciesForMostFrequestProximities.reduce(0.0, +) / Double(accuraciesForMostFrequestProximities.count)
            
            let monitoredDevice = Device(identifier: majorMinorString, rssi: beacon.rssi, proximities: newProximities, accuracies: newAccuracies, proximity: mostFrequentProximity, accuracy: simpleMovingAccuraciesAverage)
                                         
            deviceList[majorMinorString] = monitoredDevice
            if (newProximities.count == 1) || ((Date().timeIntervalSince1970 - timeSinceLastRefresh.timeIntervalSince1970) > 5) {
                sortedList.removeAll()
                let sortedValues = deviceList.values.sorted(by: {
                    $0.proximity.rawValue < $1.proximity.rawValue
                })
                sortedList.append(contentsOf: sortedValues)
                timeSinceLastRefresh = Date()
                tableView.reloadData()
            }

        }
        print(beacons)
    }

    // UITableViewController
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
        let device = sortedList[indexPath.row]
        cell.textLabel?.text = String(format: "%d -- %f", device.proximity.rawValue, device.accuracy)
        cell.detailTextLabel?.text = device.identifier
        return cell
    }
}

