//
//  ViewController.swift
//  SpeedAndLocation
//
//  Created by Jake O´Donnell on 2020-03-06.
//  Copyright © 2020 Jake O´Donnell. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import UICircularProgressRing

class ViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var circ: UICircularProgressRing!
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var averageSpeed: UILabel!
    @IBOutlet weak var timeElapsed: UILabel!
    @IBOutlet weak var travelDistance: UILabel!
    @IBOutlet weak var topSpeed: UILabel!
    @IBOutlet weak var distLabel: UILabel!
    
    var backupCounter = 0
    var averageSpeedCalc = 0.0
    var speedMeasurements = 0.0
    var speed = 0.0
    var traveledDistance: Double = 0
    var topSpeedCalc = 0.0
    var timeCount = 0
    
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    
    let locationManager = CLLocationManager()
    var startDate: Date!
    var date = Date().addingTimeInterval(1)
    var Location = CLLocation()
    var timer = Timer()

    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    var paused = true
    
    func initValues(){
        averageSpeedCalc = 0.0
        averageSpeed.text = String(averageSpeedCalc)
        speedMeasurements = 0.0
        speed = 0.0
        speedLabel.text = String(speed)
        traveledDistance = 0.0
        travelDistance.text = String(traveledDistance)
        topSpeedCalc = 0.0
        topSpeed.text = String(topSpeedCalc)
        startDate = Date()
        timeElapsed.text = "00:00:00"
        circ.startProgress(to: CGFloat(speed), duration: 2.0)
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Location = locations[0]
        if !paused {
            //Correction of speed
            if((Location.speed * 3.6) > 0){
                speed = Location.speed * 3.6
                speedLabel.text = "\(Int(speed))"
                speedMeasurements = speedMeasurements + 1.0
                averageSpeedCalc = (averageSpeedCalc + speed)
                averageSpeed.text = String(round((averageSpeedCalc / speedMeasurements) * 10) / 10)
                print(round((averageSpeedCalc / speedMeasurements) * 100) / 100)
                if speed > topSpeedCalc{
                    topSpeedCalc = speed
                    topSpeed.text = String(round(topSpeedCalc*10)/10)
                }
            }else {
                speedLabel.text = "0"
                speed = 0
            }
            if startLocation == nil {
                startLocation = locations.first
                
            } else if let location = locations.last {
                traveledDistance += lastLocation.distance(from: location)
                print("Traveled Distance:",  traveledDistance)
                print("Straight Distance:", startLocation.distance(from: locations.last!))
                if traveledDistance > 1000 {
                    travelDistance.text = String(round((traveledDistance / 1000) * 10) / 10)
                    distLabel.text = "km"
                }else {
                    travelDistance.text = String(round(traveledDistance))
                    distLabel.text = "m"
                    
                }
            }
            lastLocation = locations.last
            circ.startProgress(to: CGFloat(speed), duration: 2.0)
        }
        getPlace(for: Location) { placemark in
            if let place = placemark {
                let locality = place.locality
                print(locality!)
                self.city.text = locality!
            } else {
                print("no city found when updating location")
            }
            
        }
    }
    
    
    func getPlace(for location: CLLocation, completion: @escaping (CLPlacemark?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil else {
                completion(nil)
                return
            }
            guard let placemark = placemarks?[0] else {
                completion(nil)
                return
            }
            completion(placemark)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("fail")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resumeButton.isHidden = true
        endButton.isHidden = true
        stopButton.isHidden = true
        
        stopButton.layer.cornerRadius = 15
        startButton.layer.cornerRadius = 15
        endButton.layer.cornerRadius = 15
        resumeButton.layer.cornerRadius = 15
        
        circ.maxValue = 320
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.distanceFilter = 10
            
        }
    }
    
    @objc func doElapsed(addition: Int){
        elapsed(addition: backupCounter)
    }
    
    func elapsed(addition: Int){
        if startDate == nil {
            startDate = Date()
        } else {
            timeElapsed.text = (timeString(time: Double(Date().timeIntervalSince(startDate)) + Double(backupCounter)))
        }
    }
    
    @IBAction func startPressed(_ sender: Any) {
        timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(doElapsed), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        paused = false
        startButton.isHidden = true
        stopButton.isHidden = false
        resumeButton.isHidden = true
        endButton.isHidden = true
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        backupCounter = timeCount
        print(backupCounter)
        timer.invalidate()
        startDate = nil
        
        paused = true
        stopButton.isHidden = true
        resumeButton.isHidden = false
        endButton.isHidden = false
    }
    
    @IBAction func endPressed(_ sender: Any) {
        backupCounter = 0
        timer.invalidate()
        startDate = nil
        
        initValues()
        paused = true
        stopButton.isHidden = true
        resumeButton.isHidden = true
        endButton.isHidden = true
        startButton.isHidden = false
        
    }
    @IBAction func resumePressed(_ sender: Any) {
        lastLocation = locationManager.location
        timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(doElapsed), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        paused = false
        stopButton.isHidden = false
        resumeButton.isHidden = true
        endButton.isHidden = true
    }
    
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time / 3600)
        let minutes = Int((time - Double(hours) * 3600) / 60)
        let seconds = time - (Double(hours) * 3600 + Double(minutes) * 60)
        timeCount = Int(time)
        return String(format:"%02i:%02i:%02i",Int(hours), Int(minutes),Int(seconds))
    }
    
}

