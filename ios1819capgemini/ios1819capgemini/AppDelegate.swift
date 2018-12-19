//
//  AppDelegate.swift
//  ios1819capgemini
//
//  Created by RMMM on 06.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import UIKit
import Prototyper
import CUU

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, IKAppDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PrototyperController.showFeedbackButton = false
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "AttachmentIdentifier") == 0 {
            defaults.set(1, forKey: "AttachmentIdentifier")
        }
        if defaults.integer(forKey: "AttachedPhotoName") == 0 {
            defaults.set(1, forKey: "AttachedPhotoName")
        }
        if defaults.integer(forKey: "AttachedVideoName") == 0 {
            defaults.set(1, forKey: "AttachedVideoName")
        }
        if defaults.integer(forKey: "AttachedAudioName") == 0 {
            defaults.set(1, forKey: "AttachedAudioName")
        }
        // Override point for customization after application launch.
        
        CUU.start()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        DataHandler.loadFromJSON(url: url)
        return true
    }


    func applicationWillResignActive(_ application: UIApplication) {
        DataHandler.saveToJSON()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DataHandler.saveToJSON()
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DataHandler.saveToJSON()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        CUU.stop()
    }


}
