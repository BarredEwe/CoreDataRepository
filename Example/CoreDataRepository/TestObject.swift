//
//  TestObject.swift
//  CoreDataRepository_Example
//
//  Created by Grishutin Maksim on 21/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import BaseRepository
import CoreData
import CoreDataRepository

@objc(TestObject)
public class TestObject: NSManagedObject, ModelEntity {

    public typealias EntityType = TestStruct

    @NSManaged public var title: String!

    public var plainObject: TestStruct { return TestStruct(title: title) }
}

public struct TestStruct: Codable {
    var title = "Title"
}

extension TestStruct: Entity {
    public typealias ModelEntityType = TestObject

    public var modelObject: TestObject {
        let model = CoreDataRepository<TestObject>().newManagedObject as! TestObject
        model.title = title
        return model
    }
}
