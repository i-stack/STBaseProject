//
//  AppDelegate.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 05/16/2017.
//

import UIKit
import STBaseProject

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        STDeviceAdapter.shared.configureNavigationBar(contentHeight: 50)
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        Bundle.st_setCustomLanguage("zh-Hans")
        self.configureLogging()
        self.configureHUD()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = AppDelegate.makeRootNavigationController()
        self.window = window
        window.makeKeyAndVisible()
        return true
    }

    private func configureLogging() {
        STLogManager.bootstrap(.init(
            minimumLevel: .debug,
            persistDefaultLogs: false,
            maxFileSize: 2 * 1024 * 1024,
            maxArchivedFiles: 5,
            retainedLogCountForDisplay: 1500,
            cloudTransport: nil,
            cloudBatchSize: 20
        ))

        STPersistentLog("日志系统已完成启动", level: .info, metadata: [
            "environment": "example",
            "cloudUpload": "disabled"
        ])

        // 需要接入云端上传时，替换为你们自己的接口地址或 requestBuilder。
        // let transport = STURLSessionLogCloudTransport(
        //     endpoint: URL(string: "https://example.com/api/logs")!,
        //     headers: ["Authorization": "Bearer <token>"]
        // )
        // STLogManager.setCloudTransport(transport)
    }
    
    private func configureHUD() {
        STHUD.sharedHUD.defaultIconPosition = .left
        var theme = STHUDTheme()
//        theme.cornerRadius = 12
//        theme.shadow = .enabled
//        theme.backgroundColor = UIColor.black.withAlphaComponent(0.7)//UIColor.color(hex: "#141415").withAlphaComponent(0.7)
        theme.textColor = UIColor.white
        theme.detailTextColor = UIColor.white.withAlphaComponent(0.7)
        theme.labelFont = UIFont.st_systemFont(ofSize: 16, weight: .semibold)
        theme.detailLabelFont = UIFont.st_systemFont(ofSize: 16)
//        theme.iconSize = CGSize(width: 18, height: 18)
//        theme.successIconName = "toastsu"
//        theme.successColor = UIColor.white
//        theme.errorColor = UIColor.white
//        theme.warningColor = UIColor.white
        STHUD.sharedHUD.applyTheme(theme)
    }

    static func makeRootNavigationController() -> UINavigationController {
        let rootViewController = ViewController(nibName: "ViewController", bundle: nil)
        return UINavigationController(rootViewController: rootViewController)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // No-op for now
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
    }
}
