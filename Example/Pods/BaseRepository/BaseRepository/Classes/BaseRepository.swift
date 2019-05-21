import Foundation

public struct Sorted {
    public var key: String
    public var ascending: Bool = true
}

public protocol Entity {
    associatedtype ModelEntityType
    var modelObject: ModelEntityType { get }
}

public protocol ModelEntity {
    associatedtype EntityType: Entity
    var plainObject: EntityType { get }
}

public protocol BaseRepository: class {
    associatedtype EntityType
    /* Save an item */
    func save(item: EntityType) throws

    /* Save an array of items */
    func saveSeveral(items: [EntityType]) throws

    /* Update an item */
    func update(block: @escaping () -> Void) throws

    /* Delete items of predicate */
    func delete(predicate: NSPredicate) throws

    /* Delete all items */
    func deleteAll() throws

    /* Return a list of items  */
    func fetch(predicate: NSPredicate?, sorted: Sorted?, page: (limit: Int, offset: Int)?) -> [EntityType]

    /* Return list of all items */
    func fetchAll() -> [EntityType]
}

// swiftlint: disable identifier_name
public class AnyRepository<EntityType>: BaseRepository {

    let _save: (EntityType) throws -> Void
    let _saveSeveral: ([EntityType]) throws -> Void
    let _update: (@escaping () -> Void) throws -> Void
    let _delete: (NSPredicate) throws -> Void
    let _deleteAll: () throws -> Void
    let _fetch: (NSPredicate?, Sorted?, (limit: Int, offset: Int)?) -> [EntityType]
    let _fetchAll: () -> [EntityType]

    init<T: BaseRepository>(_ repository: T) {
        _save = repository.save as! (EntityType) throws -> Void
        _saveSeveral = repository.saveSeveral as! ([EntityType]) throws -> Void
        _update = repository.update
        _delete = repository.delete
        _deleteAll = repository.deleteAll
        _fetch = repository.fetch as! (NSPredicate?, Sorted?, (limit: Int, offset: Int)?) -> [EntityType]
        _fetchAll = repository.fetchAll as! () -> [EntityType]
    }

    public func save(item: EntityType) throws {
        try _save(item)
    }

    public func saveSeveral(items: [EntityType]) throws {
        try _saveSeveral(items)
    }

    public func update(block: @escaping () -> Void) throws {
        try _update(block)
    }

    public func delete(predicate: NSPredicate) throws {
        try _delete(predicate)
    }

    public func deleteAll() throws {
        try _deleteAll()
    }

    public func fetch(predicate: NSPredicate?, sorted: Sorted?, page: (limit: Int, offset: Int)?) -> [EntityType] {
        return _fetch(predicate, sorted, page)
    }

    public func fetchAll() -> [EntityType] {
        return _fetchAll()
    }
}
