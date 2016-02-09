//
//  NNModel.swift
//  nn
//
//  Created by Jinyue Xia on 1/11/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PromiseKit

class NNModel: NSManagedObject {
    @NSManaged var uid: NSNumber
    @NSManaged var created_at: NSNumber
    @NSManaged var modified_at: NSNumber
    @NSManaged var state: NSNumber

    /// A singleton context suitable for use from multiple threads. Operations on
    /// the context must be dont from within `context.performBlock`.
    static var concurrentContext: NSManagedObjectContext = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = app.persistentStoreCoordinator
        return context

    }()

    struct STATE {
        static let NEW = 1
        static let SAVED = 2
        static let MODIFIED = 3
        static let SYNCED = 4
        static let DOWNLOADED = 5
        static let SENDING = 6
    }

    /// - TODO: Where and how are these state values used?
    private func updateStateForSave() {
        if (state == STATE.NEW || state == STATE.SAVED){
            state = STATE.SAVED
        } else if (state == STATE.SYNCED || state == STATE.MODIFIED){
            state = STATE.MODIFIED
        } else if (state == STATE.DOWNLOADED) {
            state = STATE.SYNCED
        }
    }

    func commit() -> Void {
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        updateStateForSave()
        SwiftCoreDataHelper.saveManagedObjectContext(context)
    }

    /// An alternate version of `commit` that will propagate any errors from the operation on the context.
    /// Note that this method will save all the current changes and not just the model it is invoked on.
    func save() throws {
        updateStateForSave()
        if let context = managedObjectContext {
            try context.save()
        } else {
            throw ModelErrors.NoAssociatedContext
        }
    }

    // pull information from coredata
    // ** Deprecated ** //
    class func doPullByNameFromCoreData(entityname: String, attr: String, name: String?) -> NNModel? {
        var model: NNModel?
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let request = NSFetchRequest(entityName: entityname)
        request.returnsDistinctResults = false
        if name != nil {
            request.predicate = NSPredicate(format: "\(attr) = %@", name!)
        }
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count > 0 {
            for res in results {
                if let tModel = res as? NNModel {
                    model = tModel
                }
            }
        } else {
            print("no matched in doPullByNameFromCoreData")
        }
        return model
    }
    
    // pull information from coredata
    // ** Deprecated **
    class func doPullByUIDFromCoreData(entityname: String, uid: Int) -> NNModel? {
        var model: NNModel?
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let request = NSFetchRequest(entityName: entityname)
        request.returnsDistinctResults = false
        request.predicate = NSPredicate(format: "uid = \(uid)")
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count > 0 {
            for res in results {
                if let tModel = res as? NNModel {
                    model = tModel
                }
            }
        } else {
            print("no matched in doPullByUIDFromCoreData")
        }
        return model
    }
    
    class func fetechEntitySingle(entityname: String, predicate: NSPredicate!) -> NNModel? {
        var model: NNModel?
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let request = NSFetchRequest(entityName: entityname)
        request.returnsDistinctResults = false
        request.predicate = predicate
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count > 0 {
            for res in results {
                if let tModel = res as? NNModel {
                    model = tModel
                }
            }
        } else {
            print("no matched entity in fetechEntitySingle")
        }
        return model
    }
    
    // update local data with the server
    func updateToCoreData(data: NSDictionary) { }
    
    // update remote uid and state
    func updateAfterPost(idFromServer: Int, modifiedAtFromServer: NSNumber?) {
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        state = STATE.SYNCED
        uid = idFromServer
        if modifiedAtFromServer != nil {
            modified_at = modifiedAtFromServer!
        }
        SwiftCoreDataHelper.saveManagedObjectContext(context)
    }
    
    func push(apiService: APIService) {
        if state == STATE.SAVED || state == STATE.NEW {
            doPushNew(apiService)
        } else if state == STATE.MODIFIED || state == STATE.DOWNLOADED {
            doPushUpdate(apiService)
        }
        
    }

    func doPushNew(apiService: APIService) {}
    
    func doPushChilren(apiService: APIService) {}
    
    func doPushUpdate(apiService: APIService) {}
    
    func doCommitChildren() {}

    /// Deletes all records matching a predicate.
    ///
    /// - parameter type: the type of model to delete.
    /// - parameter matching: the conditions of the search.
    /// - returns: a promise wrapping the operation.
    class func delete<T: NNModel>(type: T.Type, matching predicate: NSPredicate) -> Promise<Int> {
        return Promise { fulfil, reject in
            concurrentContext.performBlock {
                let request = NSFetchRequest(entityName: String(type))
                request.predicate = predicate
                do {
                    let results = try concurrentContext.executeFetchRequest(request)
                    var deleted = 0
                    if results.count > 0 {
                        for obj in results {
                            concurrentContext.deleteObject(obj as! NNModel)
                        }
                        try concurrentContext.save()
                        deleted = results.count
                    }
                    fulfil(deleted)
                } catch {
                    reject(error)
                }
            }
        }
    }

    /// Deletes all records matching a predicate. The handler will be called back with the number of records deleted.
    /// The hanlder will be invoked asynchronously.
    ///
    /// - parameter type: the type of model to delete.
    /// - parameter matching: the conditions of the search.
    /// - parameter queue: which queue to execute the handler on, defaults to `Background`
    /// - parameter handler: the handler block for the results, it is guaranteed that only one of the arguments will
    ///                      be non-nil.
    class func delete<T: NNModel>(type: T.Type, matching predicate: NSPredicate, queue: Dispatch = .Background, handler: (Int?, ErrorType?) -> ()) {
        delete(type, matching: predicate)
            .then(on: queue, { handler($0, nil) })
            .error(on: queue, { handler(nil, $0) })
    }

    /// Inserts a new instance of a model into the context but does not save it.
    ///
    /// - parameter type: the type of model to insert.
    /// - returns: the newly created and inserted instance.
    class func insert<T: NNModel>(type: T.Type) -> T {
        var model: T?
        concurrentContext.performBlockAndWait {
            model = NSEntityDescription.insertNewObjectForEntityForName(String(type), inManagedObjectContext: concurrentContext) as? T
        }
        return model!
    }

    /// Attempts to find a single instance of the type specified by the predicate, if no matches are found a new instance
    /// will be created and inserted into the context. Will return an error if more then one instance was found
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - returns: a promise wrapping the operation.
    /// - SeeAlso: `findOne`
    class func findOrInsert<T: NNModel>(type: T.Type, matching predicate: NSPredicate) -> Promise<T> {
        return Promise { fulfil, reject in
            concurrentContext.performBlock {
                do {
                    let request = NSFetchRequest(entityName: String(type))
                    request.predicate = predicate
                    let result = try concurrentContext.executeFetchRequest(request)
                    let models = nonnil(result.map({ $0 as? T }))
                    if models.count > 1 {
                        reject(ModelErrors.NoUniqueRecord(models))
                    }
                    else if models.count == 1 {
                        fulfil(models.first!)
                    } else {
                        fulfil(insert(type))
                    }
                } catch {
                    reject(error)
                }
            }
        }
    }

    /// Attempts to find a single instance of the type specified by the predicate, if no matches are found a new instance
    /// will be created and inserted into the context. The handler is passed the found or created instance or with any 
    /// error that occurred during the fetch. Will return an error if more then one instance was found. The handler will 
    /// be invoked asynchronously.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - parameter queue: which queue to execute the handler on, defaults to `Background`
    /// - parameter handler: the handler block for the results, if no values match both arguments to the handler will be nil,
    ///                      otherwise it is guaranteed that only one of the arguments will be non-nil
    /// - SeeAlso: `findOne`
    class func findOrInsert<T: NNModel>(type: T.Type, matching predicate: NSPredicate, queue: Dispatch = .Background, handler: (T?, ErrorType?) -> ()) {
        findOrInsert(type, matching: predicate)
            .then(on: queue, { handler($0, nil) })
            .error(on: queue, { handler(nil, $0) })
    }


    /// Find a single instance of the type specified by the predicate. Will return an error if more then one instance
    /// was found.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - returns: a promise wrapping the operation.
    /// - SeeAlso: `findFirst`
    class func findOne<T: NNModel>(type: T.Type, matching predicate: NSPredicate) -> Promise<T?> {
        return find(type, matching: predicate)
            .then(on: .Background, { results -> T? in
                if results.count > 1 {
                    throw ModelErrors.NoUniqueRecord(results)
                }
                else {
                    return results.first
                }
            })
    }

    /// Find a single instance of the type specified by the predicate and invokes the handler block with the
    /// result or with any error that occurred during the fetch. Will return an error if more then one instance
    /// was found.  The handler will be invoked asynchronously.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - parameter queue: which queue to execute the handler on, defaults to `Background`
    /// - parameter handler: the handler block for the results, if no values match both arguments to the handler will be nil,
    ///                      otherwise it is guaranteed that only one of the arguments will be non-nil
    /// - SeeAlso: `findFirst`
    class func findOne<T: NNModel>(type: T.Type, matching predicate: NSPredicate, queue: Dispatch = .Background, handler: (T?, ErrorType?) -> ()) {
        findOne(type, matching: predicate)
            .then(on: queue, { handler($0, nil) })
            .error(on: queue, { handler(nil, $0) })
    }

    /// Find a single instance of the type specified by the predicate. If there is more then one match only the first
    /// will be returned determined by the sort descriptor if present or by the natural ordering of the store if not.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - parameter orderBy: the ordering to perform the search with.
    /// - returns: a promise wrapping the operation.
    ///                      otherwise it is guaranteed that only one of the arguments will be non-nil
    class func findFirst<T: NNModel>(type: T.Type, matching predicate: NSPredicate, orderBy: NSSortDescriptor? = nil) -> Promise<T?> {
        let request = NSFetchRequest(entityName: String(type))
        request.predicate = predicate
        request.fetchLimit = 1
        if let sorter = orderBy {
            request.sortDescriptors = [sorter]
        }
        return find(type, request: request).then(on: .Background) { $0.first }
    }

    /// Find a single instance of the type specified by the predicate and invokes the handler block with the
    /// result or with any error that occurred during the fetch. If there is more then one match only the first
    /// will be returned determined by the sort descriptor if present or by the natural ordering of the store if not.
    /// The handler will be invoked asynchronously.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - parameter orderBy: the ordering to perform the search with.
    /// - parameter queue: which queue to execute the handler on, defaults to `Background`
    /// - parameter handler: the handler block for the results, if no values match both arguments to the handler will be nil,
    ///                      otherwise it is guaranteed that only one of the arguments will be non-nil
    class func findFirst<T: NNModel>(type: T.Type, matching predicate: NSPredicate, orderBy: NSSortDescriptor? = nil, queue: Dispatch = .Background, handler: (T?, ErrorType?) -> ()) {
        findFirst(type, matching: predicate, orderBy: orderBy)
            .then(on: queue, { handler($0, nil) })
            .error(on: queue, { handler(nil, $0) })
    }

    /// Finds all instances of the type that are present in the object context as specified by a predicate.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - returns: a promise wrapping the operation.
    class func find<T: NNModel>(type: T.Type, matching predicate: NSPredicate) -> Promise<[T]> {
        let request = NSFetchRequest(entityName: String(type))
        request.predicate = predicate
        return find(type, request: request)
    }

    /// Finds all instances of the type that are present in the object context as specified by a predicate and
    /// invokes the handler block with the results or with any error that occurred during the fetch. The handler
    /// will be invoked asynchronously.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter matching: the conditions of the search.
    /// - parameter queue: which queue to execute the handler on, defaults to `Background`
    /// - parameter handler: the handler block for the results, it is guaranteed that only one of the arguments
    ///                      will be non-nil.
    class func find<T: NNModel>(type: T.Type, matching predicate: NSPredicate, queue: Dispatch = .Background, handler: ([T]?, ErrorType?) -> ()) {
        find(type, matching: predicate)
            .then(on: queue, { handler($0, nil) })
            .error(on: queue, { handler(nil, $0) })
    }

    /// Finds all instances of the type that are present in the object context as specified by the request.
    ///
    /// - parameter type: the type of the model to fetch.
    /// - parameter request: the fetch request to execute.
    /// - returns: a promise wrapping the operation.
    class func find<T: NNModel>(type: T.Type, request: NSFetchRequest) -> Promise<[T]> {
        return Promise { fulfil, reject in
            concurrentContext.performBlock {
                do {
                    let result = try concurrentContext.executeFetchRequest(request)
                    let models = nonnil(result.map({ $0 as? T }))
                    fulfil(models)
                } catch {
                    reject(error)
                }
            }
        }
    }

    /// Finds all instances of the type that are present in the object context as specified by the request and 
    /// invokes the handler block with the results or with any error that occurred during the fetch. The handler 
    /// will be invoked asynchronously.
    /// 
    /// - parameter type: the type of the model to fetch.
    /// - parameter request: the fetch request to execute.
    /// - parameter queue: which queue to execute the handler on, defaults to `Background`
    /// - parameter handler: the handler block for the results, it is guaranteed that only one of the arguments
    //                       will be non-nil.
    class func find<T: NNModel>(type: T.Type, request: NSFetchRequest, queue: Dispatch = .Background, handler: ([T]?, ErrorType?) -> ()) {
        find(type, request: request)
            .then(on: queue, { handler($0, nil) })
            .error(on: queue, { handler(nil, $0) })
    }
}

