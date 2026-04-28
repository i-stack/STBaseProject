//
//  STLocationManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import CoreLocation
import Foundation

/// 位置信息结构体
public struct STLocationInfo {
    public let name: String?
    public let country: String?
    public let latitude: Double
    public let longitude: Double
    public let locality: String?
    public let subLocality: String?
    public let thoroughfare: String?
    public let subThoroughfare: String?
    public let isoCountryCode: String?
    public let administrativeArea: String?
    public let postalCode: String?
    public let timestamp: Date
    
    public init(name: String? = nil,
                country: String? = nil,
                latitude: Double = 0.0,
                longitude: Double = 0.0,
                locality: String? = nil,
                subLocality: String? = nil,
                thoroughfare: String? = nil,
                subThoroughfare: String? = nil,
                isoCountryCode: String? = nil,
                administrativeArea: String? = nil,
                postalCode: String? = nil,
                timestamp: Date = Date()) {
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.locality = locality
        self.subLocality = subLocality
        self.thoroughfare = thoroughfare
        self.subThoroughfare = subThoroughfare
        self.isoCountryCode = isoCountryCode
        self.administrativeArea = administrativeArea
        self.postalCode = postalCode
        self.timestamp = timestamp
    }
    
    /// 获取格式化的地址字符串
    public var formattedAddress: String {
        var components: [String] = []
        
        if let thoroughfare = thoroughfare, !thoroughfare.isEmpty {
            components.append(thoroughfare)
        }
        if let subThoroughfare = subThoroughfare, !subThoroughfare.isEmpty {
            components.append(subThoroughfare)
        }
        if let subLocality = subLocality, !subLocality.isEmpty {
            components.append(subLocality)
        }
        if let locality = locality, !locality.isEmpty {
            components.append(locality)
        }
        if let administrativeArea = administrativeArea, !administrativeArea.isEmpty {
            components.append(administrativeArea)
        }
        if let country = country, !country.isEmpty {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    /// 获取坐标字符串
    public var coordinateString: String {
        return "\(latitude),\(longitude)"
    }
}

/// 位置管理器配置
public struct STLocationConfig {
    public let desiredAccuracy: CLLocationAccuracy
    public let distanceFilter: CLLocationDistance
    public let timeout: TimeInterval
    public let maximumAge: TimeInterval
    
    public init(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters,
                distanceFilter: CLLocationDistance = 10.0,
                timeout: TimeInterval = 30.0,
                maximumAge: TimeInterval = 300.0) {
        self.desiredAccuracy = desiredAccuracy
        self.distanceFilter = distanceFilter
        self.timeout = timeout
        self.maximumAge = maximumAge
    }
    
    public static let `default` = STLocationConfig()
    public static let highAccuracy = STLocationConfig(desiredAccuracy: kCLLocationAccuracyBest,
                                                      distanceFilter: 1.0,
                                                      timeout: 15.0,
                                                      maximumAge: 60.0)
    public static let lowAccuracy = STLocationConfig(desiredAccuracy: kCLLocationAccuracyKilometer,
                                                     distanceFilter: 1000.0,
                                                     timeout: 60.0,
                                                     maximumAge: 600.0)
}

/// 位置管理器错误类型
public enum STLocationError: Error, LocalizedError {
    case authorizationDenied
    case authorizationRestricted
    case locationServicesDisabled
    case timeout
    case networkError
    case geocodingFailed
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "位置权限被拒绝"
        case .authorizationRestricted:
            return "位置权限受限"
        case .locationServicesDisabled:
            return "位置服务已禁用"
        case .timeout:
            return "获取位置超时"
        case .networkError:
            return "网络错误"
        case .geocodingFailed:
            return "地理编码失败"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}

/// 位置管理器回调类型
public typealias STLocationCompletion = (Result<STLocationInfo, STLocationError>) -> Void
public typealias STLocationPermissionCompletion = (CLAuthorizationStatus) -> Void

/// 位置管理器 - CLLocationManager 的封装
public class STLocationManager: NSObject {
    
    public static let shared = STLocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var currentConfig: STLocationConfig = .default
    private var locationCompletion: STLocationCompletion?
    private var permissionCompletion: STLocationPermissionCompletion?
    private var timeoutTimer: Timer?
    private var isUpdatingLocation = false
    private var lastLocationInfo: STLocationInfo?
    private var lastLocationTime: Date?
    private let queue = DispatchQueue(label: "com.stbaselocation.queue", attributes: .concurrent)

    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = currentConfig.desiredAccuracy
        locationManager.distanceFilter = currentConfig.distanceFilter
    }
    
    public func st_configure(with config: STLocationConfig) {
        queue.async(flags: .barrier) {
            self.currentConfig = config
            self.locationManager.desiredAccuracy = config.desiredAccuracy
            self.locationManager.distanceFilter = config.distanceFilter
        }
    }
    
    public func st_requestWhenInUseAuthorization(completion: @escaping STLocationPermissionCompletion) {
        guard permissionCompletion == nil else { return }
        
        permissionCompletion = completion
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func st_requestAlwaysAuthorization(completion: @escaping STLocationPermissionCompletion) {
        guard permissionCompletion == nil else { return }
        
        permissionCompletion = completion
        locationManager.requestAlwaysAuthorization()
    }
    
    public func st_checkLocationPermission(completion: @escaping STLocationPermissionCompletion) {
        let status = CLLocationManager.authorizationStatus()
        completion(status)
    }
    
    public func st_getCurrentLocation(config: STLocationConfig? = nil, completion: @escaping STLocationCompletion) {
        guard !isUpdatingLocation else {
            completion(.failure(.unknown(NSError(domain: "STLocationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "正在获取位置中"]))))
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        
        let status = CLLocationManager.authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            completion(.failure(.authorizationDenied))
            return
        }
        
        if let lastLocation = lastLocationInfo,
           let lastTime = lastLocationTime,
           Date().timeIntervalSince(lastTime) < currentConfig.maximumAge {
            completion(.success(lastLocation))
            return
        }
        
        if let newConfig = config {
            st_configure(with: newConfig)
        }
        
        locationCompletion = completion
        isUpdatingLocation = true
        startTimeoutTimer()
        
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    public func st_startUpdatingLocation(config: STLocationConfig? = nil, completion: @escaping STLocationCompletion) {
        if let newConfig = config {
            st_configure(with: newConfig)
        }
        
        locationCompletion = completion
        isUpdatingLocation = true
        
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        
        let status = CLLocationManager.authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            completion(.failure(.authorizationDenied))
            return
        }
        
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    public func st_stopUpdatingLocation() {
        queue.async(flags: .barrier) {
            self.isUpdatingLocation = false
            self.locationCompletion = nil
            self.cancelTimeoutTimer()
        }
        
        DispatchQueue.main.async {
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    public func st_getLastKnownLocation() -> STLocationInfo? {
        return queue.sync {
            return lastLocationInfo
        }
    }
    
    public func st_clearLocationCache() {
        queue.async(flags: .barrier) {
            self.lastLocationInfo = nil
            self.lastLocationTime = nil
        }
    }
    
    private func startTimeoutTimer() {
        cancelTimeoutTimer()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: currentConfig.timeout, repeats: false) { [weak self] _ in
            self?.handleLocationTimeout()
        }
    }
    
    private func cancelTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    private func handleLocationTimeout() {
        queue.async(flags: .barrier) {
            self.isUpdatingLocation = false
            let completion = self.locationCompletion
            self.locationCompletion = nil
            self.cancelTimeoutTimer()
            
            DispatchQueue.main.async {
                self.locationManager.stopUpdatingLocation()
                completion?(.failure(.timeout))
            }
        }
    }
    
    private func processLocation(_ location: CLLocation) {
        let age = Date().timeIntervalSince(location.timestamp)
        guard age < currentConfig.maximumAge else { return }
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self else { return }
            
            guard let placemark = placemarks?.first else {
                self.queue.async(flags: .barrier) {
                    let completion = self.locationCompletion
                    self.locationCompletion = nil
                    self.isUpdatingLocation = false
                    self.cancelTimeoutTimer()
                    
                    DispatchQueue.main.async {
                        self.locationManager.stopUpdatingLocation()
                        completion?(.failure(.geocodingFailed))
                    }
                }
                return
            }
            
            let locationInfo = STLocationInfo(
                name: placemark.name,
                country: placemark.country,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locality: placemark.locality,
                subLocality: placemark.subLocality,
                thoroughfare: placemark.thoroughfare,
                subThoroughfare: placemark.subThoroughfare,
                isoCountryCode: placemark.isoCountryCode,
                administrativeArea: placemark.administrativeArea,
                postalCode: placemark.postalCode,
                timestamp: location.timestamp
            )
            
            self.queue.async(flags: .barrier) {
                self.lastLocationInfo = locationInfo
                self.lastLocationTime = Date()
                
                let completion = self.locationCompletion
                self.locationCompletion = nil
                self.isUpdatingLocation = false
                self.cancelTimeoutTimer()
                
                DispatchQueue.main.async {
                    self.locationManager.stopUpdatingLocation()
                    completion?(.success(locationInfo))
                }
            }
        }
    }
}

extension STLocationManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.permissionCompletion?(status)
            self.permissionCompletion = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        processLocation(location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        queue.async(flags: .barrier) {
            let completion = self.locationCompletion
            self.locationCompletion = nil
            self.isUpdatingLocation = false
            self.cancelTimeoutTimer()
            
            DispatchQueue.main.async {
                self.locationManager.stopUpdatingLocation()
                completion?(.failure(.unknown(error)))
            }
        }
    }
}
