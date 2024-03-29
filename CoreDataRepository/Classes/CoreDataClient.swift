//
//  CoreDataClient.swift
//  CoreDataRepository
//
//  Created by Grishutin Maksim on 21/05/2019.
//


import Foundation
import CoreData

class CoreDataClient {

    static let shared = CoreDataClient()

    lazy var context: NSManagedObjectContext = {
        return persistentContainer.viewContext
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

    lazy var backgroundContext: NSManagedObjectContext = {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = context

        return privateContext
    }()

    var currentContext: NSManagedObjectContext {
        if Thread.isMainThread {
            return context
        } else {
            return backgroundContext
        }
    }

    func saveContext(context: NSManagedObjectContext, completion: (() -> ())? = nil) {
        guard context.hasChanges else { return }
        do {
            try context.save()
            if let c = completion { c() }
        }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    func delete(objects: [NSManagedObject], context: NSManagedObjectContext) {
        for object in objects {
            context.delete(object)
        }
    }

    func deleteAllObjects(context: NSManagedObjectContext) {
        for entityName in managedObjectModel.entitiesByName.keys {
            let request = NSFetchRequest<NSManagedObjectID>(entityName: entityName)
            request.resultType = .managedObjectIDResultType

            do {
                let result = try context.fetch(request)
                result.forEach { context.delete(context.object(with: $0)) }
                self.saveContext(context: context)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }

    func fetchObjects<T: NSManagedObject>(entity: T.Type,
                                          predicate: NSPredicate? = nil,
                                          sortDescriptors: [NSSortDescriptor]? = nil,
                                          context: NSManagedObjectContext,
                                          page: (limit: Int, offset: Int)? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = page?.limit ?? 0
        request.fetchOffset = page?.offset ?? 0

        do {
            return try context.fetch(request)
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return [T]()
        }
    }
}
