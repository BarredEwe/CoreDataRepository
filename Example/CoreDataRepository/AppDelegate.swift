//
//  AppDelegate.swift
//  CoreDataRepository
//
//  Created by BarredEwe on 05/21/2019.
//  Copyright (c) 2019 BarredEwe. All rights reserved.
//

import UIKit
import CoreDataRepository

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        config.persistentContainerName = "Test"
        return true
    }
}

