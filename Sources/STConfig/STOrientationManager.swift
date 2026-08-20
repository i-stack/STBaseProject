//
//  STOrientationManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/06/30.
//

import UIKit

/// SDK 屏幕方向相关错误
public enum STOrientationError: Error, LocalizedError {
    /// 当前没有可用（已连接/前台活跃）的 UIWindowScene，无法请求几何更新。
    /// 常见于 `didFinishLaunching` 或 Scene 尚未连接时。
    case windowSceneUnavailable
    /// 系统拒绝几何更新请求。
    case geometryUpdateFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .windowSceneUnavailable:
            return NSLocalizedString("STOrientationError: 未找到可用的 UIWindowScene", comment: "")
        case .geometryUpdateFailed(let error):
            return NSLocalizedString("STOrientationError: 几何更新失败 - \(error.localizedDescription)", comment: "")
        }
    }
}

public final class STOrientationManager {

    public static let shared = STOrientationManager()

    /// 默认方向范围（只读对外，修改请走 `setDefaultOrientation`，以保证通知统一发出）
    public private(set) var defaultInterfaceOrientations: UIInterfaceOrientationMask = .portrait

    /// 宿主 App 在 `application(_:supportedInterfaceOrientationsFor:)` 中应返回此值，
    /// 使系统旋转范围与 SDK 当前方向保持一致。
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let provider = self.orientationMaskProvider {
            return provider()
        }
        return self.overrideInterfaceOrientations ?? self.defaultInterfaceOrientations
    }

    /// 供 AppDelegate/SceneDelegate 的 `supportedInterfaceOrientationsFor` 调用。
    /// 默认实现直接返回 `supportedInterfaceOrientations`，也可由宿主替换为返回 window 级别的值。
    public var orientationMaskProvider: (() -> UIInterfaceOrientationMask)?

    /// 几何更新失败回调，调用方可据此提示用户或回退。
    public var onGeometryUpdateFailed: ((Error) -> Void)?

    private var overrideInterfaceOrientations: UIInterfaceOrientationMask?

    private init() {}

    /// 修改默认方向范围并通知订阅方（统一入口，避免外部直接改属性漏掉通知）
    public func setDefaultOrientation(_ mask: UIInterfaceOrientationMask) {
        self.defaultInterfaceOrientations = mask
        self.notifyMaskChanged()
    }

    public func requestInterfaceOrientations(_ orientations: UIInterfaceOrientationMask, in windowScene: UIWindowScene? = nil) {
        self.overrideInterfaceOrientations = orientations
        self.notifyMaskChanged()
        self.requestGeometryUpdate(orientations, in: windowScene)
    }

    public func restoreDefaultInterfaceOrientations(in windowScene: UIWindowScene? = nil) {
        self.overrideInterfaceOrientations = nil
        self.notifyMaskChanged()
        self.requestGeometryUpdate(self.defaultInterfaceOrientations, in: windowScene)
    }

    /// 通知方向范围变化，便于宿主在 `setNeedsUpdateOfSupportedInterfaceOrientations` 后同步。
    private func notifyMaskChanged() {
        self.onSupportedInterfaceOrientationsChanged?()
    }

    /// 当 `supportedInterfaceOrientations` 变化时触发，宿主可调用
    /// `windowScene.requestGeometryUpdate` 或刷新当前视图控制器。
    public var onSupportedInterfaceOrientationsChanged: (() -> Void)?

    private func requestGeometryUpdate(_ orientations: UIInterfaceOrientationMask, in windowScene: UIWindowScene?) {
        guard let targetWindowScene = windowScene ?? self.activeWindowScene() else {
            STLog("[STOrientationManager] No active UIWindowScene found; cannot request geometry update.")
            self.onGeometryUpdateFailed?(STOrientationError.windowSceneUnavailable)
            return
        }
        targetWindowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { [weak self] error in
            STLog("[STOrientationManager] requestGeometryUpdate failed: \(error.localizedDescription)")
            self?.onGeometryUpdateFailed?(STOrientationError.geometryUpdateFailed(error))
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
