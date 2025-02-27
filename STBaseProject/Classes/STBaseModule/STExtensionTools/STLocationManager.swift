//
//  STLocationManager.swift
//  UrtyePbhk
//
//  Created by song on 2025/1/19.
//

import CoreLocation

public class STLocationManager: NSObject, CLLocationManagerDelegate {
    
    public struct LocationInfo {
        var name: String?
        var country: String?
        var latitude: String?
        var longitude: String?
        var locality: String?
        var subLocality: String?
        var thoroughfare: String?
        var subThoroughfare: String?
        var isoCountryCode: String?
        var administrativeArea: String?
    }
    
    static let shared: STLocationManager = STLocationManager()
    private let locationManager = CLLocationManager()
    private var locationdidUpdateResult: ((LocationInfo, Error?) -> Void)?
    private var authLocationStatusCallback: ((CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        self.locationManager.delegate = self
    }
    
    public func st_requestWhenInUseAuthorization(callback: @escaping (CLAuthorizationStatus) -> Void) {
        self.authLocationStatusCallback = callback
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    public func st_requestAlwaysAuthorization(callback: @escaping (CLAuthorizationStatus) -> Void) {
        self.authLocationStatusCallback = callback
        self.locationManager.requestAlwaysAuthorization()
    }
    
    /// Calling this method will not pop up a system prompt box.
    ///
    /// If you want to pop up a system prompt box, please use`requestWhenInUseAuthorization` or `requestAlwaysAuthorization`
    ///
    /// This method only retrun CLAuthorizationStatus
    ///
    public func st_requestLocationPermission(callback: @escaping (CLAuthorizationStatus) -> Void) {
        if self.authLocationStatusCallback != nil { return }
        self.authLocationStatusCallback = callback
        let status = CLLocationManager.authorizationStatus()
        if status != .notDetermined {
            callback(status)
            self.authLocationStatusCallback = nil
        } else {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    public func st_startUpdatingLocation(complection: @escaping(LocationInfo, Error?) -> Void) {
        self.locationdidUpdateResult = complection
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.startLocationUpdates()
        }
    }
    
    private func startLocationUpdates() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
        }
    }
    
    public func st_stopUpdatingLocation() {
        DispatchQueue.main.async {
            self.locationManager.stopUpdatingLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let callBack = self.authLocationStatusCallback {
            callBack(status)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        CLGeocoder().reverseGeocodeLocation(location) {[weak self] placemarks, error in
            guard let strongSelf = self else { return }
            guard let placemark = placemarks?.first, error == nil else { return }
            var infoModel = LocationInfo()
            infoModel.name = placemark.name ?? ""
            infoModel.country = placemark.country ?? ""
            infoModel.latitude = String(latitude)
            infoModel.longitude = String(longitude)
            infoModel.locality = placemark.locality ?? ""
            infoModel.subLocality = placemark.subLocality ?? ""
            infoModel.thoroughfare = placemark.thoroughfare ?? ""
            infoModel.subThoroughfare = placemark.subThoroughfare ?? ""
            infoModel.isoCountryCode = placemark.isoCountryCode ?? ""
            infoModel.administrativeArea = placemark.administrativeArea ?? ""
            strongSelf.locationdidUpdateResult?(infoModel, nil)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationdidUpdateResult?(LocationInfo(), error)
    }
}
