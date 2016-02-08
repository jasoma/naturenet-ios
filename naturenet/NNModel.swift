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

/// Collection of errors that can occur when dealing with models locally
/// or with response from the server.
enum ModelErrors: ErrorType {

    /// Not enough data is present to create a model instance. Contains the dictionary
    /// that was used to attempt a creation.
    case IncompleteData(NSDictionary)

    /// The response from the server was not what the model expected.
    case CouldNotReadResponse(AnyObject)

    /// Too many matching records were found during an `NNModel.findOne` call. All matching
    /// records are attached.
    case NoUniqueRecord([NNModel])

    /// A save was attempted on an instance that was not linked to any context.
    case NoAssociatedContext

    /// Device has no internet access
    case NotConnected
}

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
        concurrentContext.performBlock {
            do {
                let request = NSFetchRequest(entityName: String(type))
                request.predicate = predicate
                let result = try concurrentContext.executeFetchRequest(request)
                let models = nonnil(result.map({ $0 as? T }))
                if models.count > 1 {
                    queue ~> { handler(nil, ModelErrors.NoUniqueRecord(models)) }
                }
                else if models.count == 1 {
                    queue ~> { handler(models.first, nil) }
                } else {
                    let inserted = NNModel.insert(type)
                    queue ~> { handler(inserted, nil) }
                }
            } catch {
                queue ~> { handler(nil, error) }
            }
        }
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
        find(type, matching: predicate, queue: queue) { results, error in
            if error != nil {
                handler(nil, error)
            }
            else if results?.count > 1 {
                handler(nil, ModelErrors.NoUniqueRecord(results!))
            }
            else {
                handler(results?.first, nil)
            }
        }
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
        let request = NSFetchRequest(entityName: String(type))
        request.predicate = predicate
        request.fetchLimit = 1
        if let sorter = orderBy {
            request.sortDescriptors = [sorter]
        }
        find(type, request: request, queue: queue) { results, error in
            if error != nil {
                handler(nil, error)
            }
            else {
                handler(results?.first, nil)
            }
        }
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
        let request = NSFetchRequest(entityName: String(type))
        request.predicate = predicate
        find(type, request: request, queue: queue, handler: handler)
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
        concurrentContext.performBlock {
            do {
                let result = try concurrentContext.executeFetchRequest(request)
                let models = nonnil(result.map({ $0 as? T }))
                queue ~> { handler(models, nil) }
            } catch {
                queue ~> { handler(nil, error) }
            }
        }
    }
}

