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
    /// geocodingFailed 携带底层错误，便于排查是网络问题还是区域不支持
    case geocodingFailed(Error?)
    /// 已有请求进行中，拒绝并发调用
    case busy
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:        return "位置权限被拒绝"
        case .authorizationRestricted:    return "位置权限受限"
        case .locationServicesDisabled:   return "位置服务已禁用"
        case .timeout:                    return "获取位置超时"
        case .networkError:               return "网络错误"
        case .geocodingFailed(let e):     return e.map { "地理编码失败: \($0.localizedDescription)" } ?? "地理编码失败"
        case .busy:                       return "正在获取位置中"
        case .unknown(let error):         return "未知错误: \(error.localizedDescription)"
        }
    }
}

@MainActor
public protocol STLocationManagerProtocol: AnyObject {
    func st_configure(with config: STLocationConfig)
    func st_requestWhenInUseAuthorization(completion: @escaping (CLAuthorizationStatus) -> Void)
    func st_requestAlwaysAuthorization(completion: @escaping (CLAuthorizationStatus) -> Void)
    func st_checkLocationPermission(completion: @escaping (CLAuthorizationStatus) -> Void)
    func st_getCurrentLocation(config: STLocationConfig?, completion: @escaping (Result<STLocationInfo, STLocationError>) -> Void)
    func st_startUpdatingLocation(config: STLocationConfig?, completion: @escaping (Result<STLocationInfo, STLocationError>) -> Void)
    func st_stopUpdatingLocation()
    func st_getLastKnownLocation() -> STLocationInfo?
    func st_clearLocationCache()
}

// MARK: - Internal protocols for testability

protocol STCLLocationManaging: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    func isLocationServicesEnabled() -> Bool
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: STCLLocationManaging {
    func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
}

protocol STCLGeocoderProtocol: AnyObject {
    var isGeocoding: Bool { get }
    func reverseGeocodeLocation(_ location: CLLocation, completionHandler: @escaping CLGeocodeCompletionHandler)
    func cancelGeocode()
}

extension CLGeocoder: STCLGeocoderProtocol {}

// MARK: - STLocationManager

/// 所有可变状态由 @MainActor 隔离，CLLocationManager 始终在主线程操作。
@MainActor
public class STLocationManager: NSObject {

    public static let shared = STLocationManager()

    private var currentConfig: STLocationConfig = .default
    private var locationCompletion: ((Result<STLocationInfo, STLocationError>) -> Void)?
    private var permissionCompletion: ((CLAuthorizationStatus) -> Void)?
    private var isUpdating = false
    /// 连续更新模式：success 时不停止 CLLocationManager，继续推送位置
    private var isContinuousUpdating = false
    /// 每次新请求自增，用于丢弃 stop→start 竞态中残留的过期 geocoding 结果
    private var requestGeneration: Int = 0
    private var lastLocationInfo: STLocationInfo?
    private var lastLocationTime: Date?
    private var timeoutTask: Task<Void, Never>?

    private var clManager: STCLLocationManaging
    private let geocoder: STCLGeocoderProtocol

    public override init() {
        let manager = CLLocationManager()
        self.clManager = manager
        self.geocoder = CLGeocoder()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = self.currentConfig.desiredAccuracy
        manager.distanceFilter = self.currentConfig.distanceFilter
    }

    /// 仅供测试使用，通过依赖注入替换底层实现
    init(clManager: STCLLocationManaging, geocoder: STCLGeocoderProtocol) {
        self.clManager = clManager
        self.geocoder = geocoder
        super.init()
        clManager.delegate = self
    }
}

// MARK: - STLocationManagerProtocol

extension STLocationManager: STLocationManagerProtocol {

    public func st_configure(with config: STLocationConfig) {
        self.currentConfig = config
        self.clManager.desiredAccuracy = config.desiredAccuracy
        self.clManager.distanceFilter = config.distanceFilter
    }

    public func st_requestWhenInUseAuthorization(completion: @escaping (CLAuthorizationStatus) -> Void) {
        guard self.permissionCompletion == nil else { return }
        self.permissionCompletion = completion
        self.clManager.requestWhenInUseAuthorization()
    }

    public func st_requestAlwaysAuthorization(completion: @escaping (CLAuthorizationStatus) -> Void) {
        guard self.permissionCompletion == nil else { return }
        self.permissionCompletion = completion
        self.clManager.requestAlwaysAuthorization()
    }

    public func st_checkLocationPermission(completion: @escaping (CLAuthorizationStatus) -> Void) {
        completion(self.clManager.authorizationStatus)
    }

    public func st_getCurrentLocation(config: STLocationConfig? = nil, completion: @escaping (Result<STLocationInfo, STLocationError>) -> Void) {
        guard !self.isUpdating else {
            completion(.failure(.busy))
            return
        }
        guard self.clManager.isLocationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        let status = self.clManager.authorizationStatus
        guard Self.isLocationAccessAuthorized(status) else {
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
        self.requestGeneration += 1
        self.locationCompletion = completion
        self.isUpdating = true
        self.isContinuousUpdating = false
        self.startTimeoutTask()
        self.clManager.startUpdatingLocation()
    }

    public func st_startUpdatingLocation(config: STLocationConfig? = nil, completion: @escaping (Result<STLocationInfo, STLocationError>) -> Void) {
        guard !self.isUpdating else {
            completion(.failure(.busy))
            return
        }
        guard self.clManager.isLocationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        let status = self.clManager.authorizationStatus
        guard Self.isLocationAccessAuthorized(status) else {
            completion(.failure(status == .restricted ? .authorizationRestricted : .authorizationDenied))
            return
        }
        if let newConfig = config {
            self.st_configure(with: newConfig)
        }
        self.requestGeneration += 1
        self.locationCompletion = completion
        self.isUpdating = true
        self.isContinuousUpdating = true
        self.clManager.startUpdatingLocation()
    }

    public func st_stopUpdatingLocation() {
        // 自增世代号，使所有正在进行的 geocoding 回调在检查时提前退出
        self.requestGeneration += 1
        self.isContinuousUpdating = false
        self.isUpdating = false
        self.locationCompletion = nil
        self.geocoder.cancelGeocode()
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

// MARK: - Private helpers

extension STLocationManager {

    private static func isLocationAccessAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        #if os(macOS)
        return status == .authorizedAlways
        #else
        return status == .authorizedWhenInUse || status == .authorizedAlways
        #endif
    }

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
        // 位置数据过旧时跳过，等待更新的数据或超时兜底
        guard age < self.currentConfig.maximumAge else { return }
        // CLGeocoder 不支持并发，跳过已在进行中时收到的重复更新
        guard !self.geocoder.isGeocoding else { return }
        // 捕获当前世代号，用于检测 stop→start 竞态下的过期 geocoding 结果
        let capturedGeneration = self.requestGeneration
        self.geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // 若世代号已变（期间调用过 stop 或新请求），丢弃此结果
                guard self.requestGeneration == capturedGeneration else { return }
                guard let placemark = placemarks?.first else {
                    self.finishRequest(with: .failure(.geocodingFailed(error)))
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
        if self.isContinuousUpdating, case .success = result {
            // 连续模式下成功：回调但保持 CLLocationManager 运行，等待下次位置推送
            self.locationCompletion?(result)
        } else {
            // 单次模式，或连续模式下发生错误：停止一切并交付最终结果
            let completion = self.locationCompletion
            self.locationCompletion = nil
            self.isUpdating = false
            self.isContinuousUpdating = false
            self.cancelTimeoutTask()
            self.clManager.stopUpdatingLocation()
            completion?(result)
        }
    }
}

// MARK: - CLLocationManagerDelegate

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
