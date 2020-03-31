//
//  AppDelegate.swift
//  Pax
//
//  Created by Stefano Mondino on 03/30/2020.
//  Copyright (c) 2020 Stefano Mondino. All rights reserved.
//

import UIKit
import Pax
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = pax()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    func pax() -> UIViewController {
        //This usually should go on your Router, Coordinator or any other "navigation manager" you're using in your app.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let paxController = Pax()
        //A storyboard-instantiated view controller for left side
        let left = storyboard.instantiateViewController(withIdentifier: "left")
        left.view.backgroundColor = .yellow
        //A code-instantiated green view controller for right side
        let right = UIViewController()
        right.view.backgroundColor = .green
        //Main "center" view controller
        let center = storyboard.instantiateViewController(withIdentifier: "navigationController")

        //CustomWidth for both left and right side menus
        left.pax.menuWidth = UIScreen.main.bounds.width * 0.8
        right.pax.menuWidth = UIScreen.main.bounds.width * 0.6
        paxController.setViewController(left, at: .left)
        paxController.setViewController(right, at: .right)
        paxController.setMainViewController(center)
        return paxController
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

}
