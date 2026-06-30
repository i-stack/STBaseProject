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
        let targetWindowScene = windowScene ?? self.activeWindowScene()
        if #available(iOS 16.0, *), let targetWindowScene {
            targetWindowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { error in
                print("[STOrientationManager] requestGeometryUpdate failed: \(error.localizedDescription)")
            }
        } else {
            UIDevice.current.setValue(self.preferredOrientation(for: orientations).rawValue, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func preferredOrientation(for orientations: UIInterfaceOrientationMask) -> UIInterfaceOrientation {
        if orientations.contains(.portrait) { return .portrait }
        if orientations.contains(.landscapeLeft) { return .landscapeLeft }
        if orientations.contains(.landscapeRight) { return .landscapeRight }
        if orientations.contains(.portraitUpsideDown) { return .portraitUpsideDown }
        return .portrait
    }

    private func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
