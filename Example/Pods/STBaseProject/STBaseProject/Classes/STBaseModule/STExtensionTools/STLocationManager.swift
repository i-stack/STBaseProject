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
        var locality: String?
        var longitude: String?
        var subLocality: String?
        var thoroughfare: String?
        var isoCountryCode: String?
        var subThoroughfare: String?
        var administrativeArea: String?
        var errorMessage: String?
        var status: CLAuthorizationStatus?

        public init() {}
        
        public init(status: CLAuthorizationStatus? = nil, errorMessage: String? = nil) {
            self.status = status
            self.errorMessage = errorMessage
        }
    }
    
    public static let shared: STLocationManager = STLocationManager()
    private let locationManager = CLLocationManager()
    private var locationdidUpdateResult: ((LocationInfo) -> Void)?
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
        let status = CLLocationManager.authorizationStatus()
        if status != .notDetermined {
            DispatchQueue.main.async {
                callback(status)
            }
        } else {
            self.authLocationStatusCallback = callback
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    public func st_startUpdatingLocation(complection: @escaping(LocationInfo) -> Void) {
        self.locationdidUpdateResult = complection
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.startLocationUpdates()
        } else if status == .notDetermined {
            self.st_requestLocationPermission {[weak self] auStatus in
                guard let strongSelf = self else { return }
                if auStatus == .authorizedAlways || auStatus == .authorizedWhenInUse {
                    strongSelf.startLocationUpdates()
                } else {
                    let info = LocationInfo(status: auStatus)
                    DispatchQueue.main.async {
                        complection(info)
                    }
                }
            }
        } else {
            let info = LocationInfo(status: status)
            DispatchQueue.main.async {
                complection(info)
            }
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
            var infoModel = LocationInfo()
            guard let placemark = placemarks?.first, error == nil else {
                infoModel.errorMessage = error.debugDescription
                strongSelf.locationdidUpdateResult?(infoModel)
                return
            }
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
            DispatchQueue.main.async {
                strongSelf.locationdidUpdateResult?(infoModel)
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let info = LocationInfo(errorMessage: error.localizedDescription)
        self.locationdidUpdateResult?(info)
    }
}
