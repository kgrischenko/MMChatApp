//
//  AppDelegate.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 12/23/15.
//  Copyright © 2015 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Initialize MagnetMax
        let configurationFile = NSBundle.mainBundle().pathForResource("MagnetMax", ofType: "plist")
        let configuration = MMPropertyListConfiguration(contentsOfFile: configurationFile!)
        MagnetMax.configure(configuration!)
        
//        MMXLogger.sharedLogger().level = .Verbose
//        MMXLogger.sharedLogger().startLogging()
        
        let settings = UIUserNotificationSettings(forTypes: [.Badge,.Alert,.Sound], categories: nil)
        application.registerUserNotificationSettings(settings);
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("didFailToRegisterForRemoteNotificationsWithError \nCode = \(error.code) \nlocalizedDescription = \(error.localizedDescription) \nlocalizedFailureReason = \(error.localizedFailureReason)")
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        MMDevice.updateCurentDeviceToken(deviceToken, success: { () -> Void in
            print("Successfully updated device token")
        }, failure:{ (error) -> Void in
            print("Error updating device token. \(error)")
        })
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if MMXRemoteNotification.isWakeupRemoteNotification(userInfo) {
            //Send local notification to the user or connect via MMXUser logInWithCredential:success:failure:
        } else if MMXRemoteNotification.isMMXRemoteNotification(userInfo) {
            MMXRemoteNotification.acknowledgeRemoteNotification(userInfo, completion: nil)
        }
    }

}

