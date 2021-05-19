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
        let context = CoreDataClient.shared.currentContext
        processQueue.sync {
            let coreDataItem = item.modelObject
            print("Save CoreData item: \(coreDataItem)")
            self.coreDataClient.saveContext(context: context)
        }
    }

    public func saveSeveral(items: [T.EntityType]) throws {
        let context = CoreDataClient.shared.currentContext
        processQueue.sync {
            let coreDataItems = items.compactMap { $0.modelObject }
            print("Save CoreData items: \(coreDataItems)")
            coreDataClient.saveContext(context: context)
        }
    }

    public func update(block: @escaping () -> Void) throws {
        // TODO: Implementation
    }

    public func delete(predicate: NSPredicate) throws {
        let context = CoreDataClient.shared.currentContext
        processQueue.sync {
            let objects = self.coreDataClient.fetchObjects(entity: T.self, predicate: predicate, sortDescriptors: nil, context: context)
            self.coreDataClient.delete(objects: objects as [NSManagedObject], context: context)
            self.coreDataClient.saveContext(context: context)
        }
    }

    public func deleteAll() throws {
        let context = CoreDataClient.shared.currentContext
        processQueue.sync {
            coreDataClient.deleteAllObjects(context: context)
        }
    }

    public func fetch(predicate: NSPredicate?, sorted: Sorted?, page: (limit: Int, offset: Int)?) -> [T.EntityType] {
        let context = CoreDataClient.shared.currentContext
        return processQueue.sync {
            let sortDescriptor = sorted.flatMap { [NSSortDescriptor(key: $0.key, ascending: $0.ascending)] }
            let objects = coreDataClient.fetchObjects(entity: T.self, predicate: predicate, sortDescriptors: sortDescriptor, context: context)

            guard let page = page, !objects.isEmpty, page.limit != 0 else { return objects.compactMap { $0.plainObject } }

            let limit = objects.count > page.offset + page.limit ? page.offset + page.limit : objects.count
            let offset = objects.count < page.offset ? objects.count : page.offset

            return objects[offset..<limit].compactMap { $0.plainObject }
        }
    }

    public func fetchAll() -> [T.EntityType] {
        let context = CoreDataClient.shared.currentContext
        return processQueue.sync {
            return coreDataClient.fetchObjects(entity: T.self, predicate: nil, sortDescriptors: nil, context: context)
                .compactMap { $0.plainObject }
        }
    }
}
