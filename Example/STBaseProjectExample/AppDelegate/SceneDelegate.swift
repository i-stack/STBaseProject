//
//  AppDelegate.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 05/16/2017.
//  Copyright (c) 2019 STBaseProject. All rights reserved.
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

