//
//  CoreDataConfiguration.swift
//  BaseRepository
//
//  Created by Grishutin Maksim on 21/05/2019.
//

import Foundation

public var config = CoreDataConfiguration.shared

@objcMembers public class CoreDataConfiguration: NSObject {
    public static let shared = CoreDataConfiguration()
    public var persistentContainerName = Bundle.main.infoDictionary!["CFBundleName"] as! String
}
