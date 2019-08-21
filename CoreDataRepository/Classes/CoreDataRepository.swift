//
//  Created by grishutin on 19/12/2017.
//  Copyright © 2017 bifit. All rights reserved.
//

import Foundation
import BaseRepository
import CoreData

public class CoreDataRepository<T: ModelEntity>: BaseRepository where T == T.EntityType.ModelEntityType, T: NSManagedObject {

    public typealias EntityType = T.EntityType

    private let coreDataClient = CoreDataClient.shared

    public var entity: NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: T.self), in: coreDataClient.context)!
    }

    public var newManagedObject: NSManagedObject {
        return NSManagedObject(entity: self.entity, insertInto: coreDataClient.context)
    }

    public init() { }

    public func save(item: T.EntityType) throws {
        let coreDataItem = item.modelObject
        print("Save CoreData item: \(coreDataItem)")
        coreDataClient.saveContext()
    }

    public func saveSeveral(items: [T.EntityType]) throws {
        let coreDataItems = items.compactMap { $0.modelObject }
        print("Save CoreData items: \(coreDataItems)")
        coreDataClient.saveContext()
    }

    public func update(block: @escaping () -> Void) throws {
        // TODO: Implementation
    }

    public func delete(predicate: NSPredicate) throws {
        let objects = coreDataClient.fetchObjects(entity: T.self, predicate: predicate, sortDescriptors: nil)
        coreDataClient.delete(objects: objects as [NSManagedObject]);
        coreDataClient.saveContext()
    }

    public func deleteAll() throws {
        coreDataClient.deleteAllObjects()
    }

    public func fetch(predicate: NSPredicate?, sorted: Sorted?, page: (limit: Int, offset: Int)?) -> [T.EntityType] {
        let sortDescriptor = sorted.flatMap { [NSSortDescriptor(key: $0.key, ascending: $0.ascending)] }
        let objects = coreDataClient.fetchObjects(entity: T.self, predicate: predicate, sortDescriptors: sortDescriptor)

        guard let page = page, !objects.isEmpty, page.limit != 0 else { return objects.compactMap { $0.plainObject } }

        let limit = objects.count > page.offset + page.limit ? page.offset + page.limit : objects.count
        let offset = objects.count < page.offset ? objects.count : page.offset

        return objects[offset..<limit].compactMap { $0.plainObject }
    }

    public func fetchAll() -> [T.EntityType] {
        return coreDataClient.fetchObjects(entity: T.self, predicate: nil, sortDescriptors: nil)
            .compactMap { $0.plainObject }
    }
}

class CoreDataClient {

    static let shared = CoreDataClient()

    var defaultFetchBatchSize = 20

    lazy var context: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        let projectName = CoreDataConfiguration.persistentContainerName
        let container = NSPersistentContainer(name: projectName, managedObjectModel: managedObjectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        guard let url = CoreDataConfiguration.objectURL,
            let managedObjectModel = NSManagedObjectModel(contentsOf: url) else { fatalError("Failed to created managed object model") }
        return managedObjectModel
    }()

    func saveContext(completion: (() -> ())? = nil) {
        if self.context.hasChanges {
            do {
                try self.context.save()
                if let c = completion { c() }
            }
            catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func delete(objects: [NSManagedObject]) {
        for object in objects {
            context.delete(object)
        }
    }

    func deleteAllObjects() {
        for entityName in managedObjectModel.entitiesByName.keys {

            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.includesPropertyValues = false

            do {
                for object in try context.fetch(request) {
                    context.delete(object)
                }
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }

    func fetchObject<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> T? {

        let request = NSFetchRequest<T>(entityName: String(describing: entity))

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }

    func fetchObjects<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {

        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = defaultFetchBatchSize

        do {
            return try context.fetch(request)
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return [T]()
        }
    }

}
