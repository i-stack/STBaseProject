//
//  STOrientationManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/06/30.
//

import UIKit

public final class STOrientationManager {

    public static let shared = STOrientationManager()

    public var defaultInterfaceOrientations: UIInterfaceOrientationMask = .portrait

    public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        self.overrideInterfaceOrientations ?? self.defaultInterfaceOrientations
    }

    private var overrideInterfaceOrientations: UIInterfaceOrientationMask?

    private init() {}

    public func requestInterfaceOrientations(_ orientations: UIInterfaceOrientationMask, in windowScene: UIWindowScene? = nil) {
        self.overrideInterfaceOrientations = orientations
        self.requestGeometryUpdate(orientations, in: windowScene)
    }

    public func restoreDefaultInterfaceOrientations(in windowScene: UIWindowScene? = nil) {
        self.overrideInterfaceOrientations = nil
        self.requestGeometryUpdate(self.defaultInterfaceOrientations, in: windowScene)
    }

    private func requestGeometryUpdate(_ orientations: UIInterfaceOrientationMask, in windowScene: UIWindowScene?) {
        guard let targetWindowScene = windowScene ?? self.activeWindowScene() else {
            STLog("[STOrientationManager] No active UIWindowScene found; cannot request geometry update.")
            return
        }
        targetWindowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { error in
            STLog("[STOrientationManager] requestGeometryUpdate failed: \(error.localizedDescription)")
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
