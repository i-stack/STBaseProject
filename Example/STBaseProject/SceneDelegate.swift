//
//  SceneDelegate.swift
//  STBaseProject_Example
//
//  Created to adopt UIScene lifecycle for iOS 13+.
//

import UIKit
import STBaseProject

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = AppDelegate.makeRootNavigationController()
        self.window = window
        window.makeKeyAndVisible()
    }
}

