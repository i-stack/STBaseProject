//
//  STLocationManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import CoreLocation
import Foundation

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

    public var formattedAddress: String {
        var components: [String] = []
        if let v = self.thoroughfare, !v.isEmpty { components.append(v) }
        if let v = self.subThoroughfare, !v.isEmpty { components.append(v) }
        if let v = self.subLocality, !v.isEmpty { components.append(v) }
        if let v = self.locality, !v.isEmpty { components.append(v) }
        if let v = self.administrativeArea, !v.isEmpty { components.append(v) }
        if let v = self.country, !v.isEmpty { components.append(v) }
        return components.joined(separator: ", ")
    }

    public var coordinateString: String {
        return "\(self.latitude),\(self.longitude)"
    }
}

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
        case .authorizationDenied:       return "位置权限被拒绝"
        case .authorizationRestricted:   return "位置权限受限"
        case .locationServicesDisabled:  return "位置服务已禁用"
        case .timeout:                   return "获取位置超时"
        case .networkError:              return "网络错误"
        case .geocodingFailed:           return "地理编码失败"
        case .unknown(let error):        return "未知错误: \(error.localizedDescription)"
        }
    }
}

@MainActor
public protocol STLocationManagerProtocol: AnyObject {
    func st_configure(with config: STLocationConfig)
    func st_requestWhenInUseAuthorization(completion: @escaping STLocationPermissionCompletion)
    func st_requestAlwaysAuthorization(completion: @escaping STLocationPermissionCompletion)
    func st_checkLocationPermission(completion: @escaping STLocationPermissionCompletion)
    func st_getCurrentLocation(config: STLocationConfig?, completion: @escaping STLocationCompletion)
    func st_startUpdatingLocation(config: STLocationConfig?, completion: @escaping STLocationCompletion)
    func st_stopUpdatingLocation()
    func st_getLastKnownLocation() -> STLocationInfo?
    func st_clearLocationCache()
}

/// 所有可变状态由 @MainActor 隔离，CLLocationManager 始终在主线程操作。
@MainActor
public class STLocationManager: NSObject {

    public static let shared = STLocationManager()

    private var currentConfig: STLocationConfig = .default
    private var locationCompletion: STLocationCompletion?
    private var permissionCompletion: STLocationPermissionCompletion?
    private var isUpdating = false
    private var lastLocationInfo: STLocationInfo?
    private var lastLocationTime: Date?
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
    }

    private lazy var clManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = self.currentConfig.desiredAccuracy
        manager.distanceFilter = self.currentConfig.distanceFilter
        return manager
    }()

    private lazy var geocoder = CLGeocoder()
}

extension STLocationManager: STLocationManagerProtocol {

    public func st_configure(with config: STLocationConfig) {
        self.currentConfig = config
        self.clManager.desiredAccuracy = config.desiredAccuracy
        self.clManager.distanceFilter = config.distanceFilter
    }

    public func st_requestWhenInUseAuthorization(completion: @escaping STLocationPermissionCompletion) {
        guard self.permissionCompletion == nil else { return }
        self.permissionCompletion = completion
        self.clManager.requestWhenInUseAuthorization()
    }

    public func st_requestAlwaysAuthorization(completion: @escaping STLocationPermissionCompletion) {
        guard self.permissionCompletion == nil else { return }
        self.permissionCompletion = completion
        self.clManager.requestAlwaysAuthorization()
    }

    public func st_checkLocationPermission(completion: @escaping STLocationPermissionCompletion) {
        completion(self.clManager.authorizationStatus)
    }

    public func st_getCurrentLocation(config: STLocationConfig? = nil, completion: @escaping STLocationCompletion) {
        guard !self.isUpdating else {
            completion(.failure(.unknown(NSError(domain: "STLocationManager",
                                                 code: -1,
                                                 userInfo: [NSLocalizedDescriptionKey: "正在获取位置中"]))))
            return
        }
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        let status = self.clManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            completion(.failure(status == .restricted ? .authorizationRestricted : .authorizationDenied))
            return
        }
        if let last = self.lastLocationInfo,
           let lastTime = self.lastLocationTime,
           Date().timeIntervalSince(lastTime) < self.currentConfig.maximumAge {
            completion(.success(last))
            return
        }
        if let newConfig = config {
            self.st_configure(with: newConfig)
        }
        self.locationCompletion = completion
        self.isUpdating = true
        self.startTimeoutTask()
        self.clManager.startUpdatingLocation()
    }

    public func st_startUpdatingLocation(config: STLocationConfig? = nil, completion: @escaping STLocationCompletion) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        let status = self.clManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            completion(.failure(status == .restricted ? .authorizationRestricted : .authorizationDenied))
            return
        }
        if let newConfig = config {
            self.st_configure(with: newConfig)
        }
        self.locationCompletion = completion
        self.isUpdating = true
        self.clManager.startUpdatingLocation()
    }

    public func st_stopUpdatingLocation() {
        self.isUpdating = false
        self.locationCompletion = nil
        self.cancelTimeoutTask()
        self.clManager.stopUpdatingLocation()
    }

    public func st_getLastKnownLocation() -> STLocationInfo? {
        return self.lastLocationInfo
    }

    public func st_clearLocationCache() {
        self.lastLocationInfo = nil
        self.lastLocationTime = nil
    }
}

extension STLocationManager {
    private func startTimeoutTask() {
        self.cancelTimeoutTask()
        let timeout = self.currentConfig.timeout
        self.timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled, let self = self else { return }
            self.handleLocationTimeout()
        }
    }

    private func cancelTimeoutTask() {
        self.timeoutTask?.cancel()
        self.timeoutTask = nil
    }

    private func handleLocationTimeout() {
        self.cancelTimeoutTask()
        self.finishRequest(with: .failure(.timeout))
    }

    private func processLocation(_ location: CLLocation) {
        let age = Date().timeIntervalSince(location.timestamp)
        guard age < self.currentConfig.maximumAge else { return }
        self.geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard let placemark = placemarks?.first else {
                    self.finishRequest(with: .failure(.geocodingFailed))
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
                self.lastLocationInfo = locationInfo
                self.lastLocationTime = Date()
                self.finishRequest(with: .success(locationInfo))
            }
        }
    }

    private func finishRequest(with result: Result<STLocationInfo, STLocationError>) {
        let completion = self.locationCompletion
        self.locationCompletion = nil
        self.isUpdating = false
        self.cancelTimeoutTask()
        self.clManager.stopUpdatingLocation()
        completion?(result)
    }
}

extension STLocationManager: CLLocationManagerDelegate {
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.permissionCompletion?(status)
            self?.permissionCompletion = nil
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            self?.processLocation(location)
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.finishRequest(with: .failure(.unknown(error)))
        }
    }
}
