//
//  Created by grishutin on 19/12/2017.
//  Copyright © 2017 bifit. All rights reserved.
//

import Foundation
import BaseRepository
import CoreData

fileprivate let processQueue = DispatchQueue(label: "CoreDataRepository.processQueue")

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
        processQueue.sync {
            coreDataClient.context.perform {
                let coreDataItem = item.modelObject
                print("Save CoreData item: \(coreDataItem)")
                self.coreDataClient.saveContext()
            }
        }
    }

    public func saveSeveral(items: [T.EntityType]) throws {
        processQueue.sync {
            let coreDataItems = items.compactMap { $0.modelObject }
            print("Save CoreData items: \(coreDataItems)")
            coreDataClient.saveContext()
        }
    }

    public func update(block: @escaping () -> Void) throws {
        // TODO: Implementation
    }

    public func delete(predicate: NSPredicate) throws {
        processQueue.sync {
            coreDataClient.context.perform {
                let objects = self.coreDataClient.fetchObjects(entity: T.self, predicate: predicate, sortDescriptors: nil)
                self.coreDataClient.delete(objects: objects as [NSManagedObject])
                self.coreDataClient.saveContext()
            }
        }
    }

    public func deleteAll() throws {
        processQueue.sync {
            coreDataClient.deleteAllObjects()
        }
    }

    public func fetch(predicate: NSPredicate?, sorted: Sorted?, page: (limit: Int, offset: Int)?) -> [T.EntityType] {
        processQueue.sync {
            let sortDescriptor = sorted.flatMap { [NSSortDescriptor(key: $0.key, ascending: $0.ascending)] }
            let objects = coreDataClient.fetchObjects(entity: T.self, predicate: predicate, sortDescriptors: sortDescriptor)

            guard let page = page, !objects.isEmpty, page.limit != 0 else { return objects.compactMap { $0.plainObject } }

            let limit = objects.count > page.offset + page.limit ? page.offset + page.limit : objects.count
            let offset = objects.count < page.offset ? objects.count : page.offset

            return objects[offset..<limit].compactMap { $0.plainObject }
        }
    }

    public func fetchAll() -> [T.EntityType] {
        processQueue.sync {
            return coreDataClient.fetchObjects(entity: T.self, predicate: nil, sortDescriptors: nil)
                .compactMap { $0.plainObject }
        }
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
        guard self.context.hasChanges else { return }
        do {
            try self.context.save()
            if let c = completion { c() }
        }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    func delete(objects: [NSManagedObject]) {
        context.perform {
            for object in objects {
                self.context.delete(object)
            }
        }
    }

    func deleteAllObjects() {
        for entityName in managedObjectModel.entitiesByName.keys {
            let request = NSFetchRequest<NSManagedObjectID>(entityName: entityName)
            request.resultType = .managedObjectIDResultType

            let mainContext = self.context

            mainContext.perform {
                do {
                    let result = try mainContext.fetch(request)
                    result.forEach { mainContext.delete(mainContext.object(with: $0)) }
                    self.saveContext()
                }
                catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func fetchObject<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing: entity))

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = 1

        var result: T?
        context.performAndWait {
            do {
                result = try context.fetch(request).first
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        return result
    }

    func fetchObjects<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = defaultFetchBatchSize

        var result = [T]()
        context.performAndWait {
            do {
                result = try context.fetch(request)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        return result
    }
}
