//
//  NNModelTestExtensions.swift
//  NatureNet
//
//  Created by Jason Maher on 2/8/16.
//
//

import Foundation
import CoreData

@testable import NatureNet

extension NNModel {

    /// Deletes all records of the specified type.
    static func deleteAll<T: NSManagedObject>(type: T.Type) {
        concurrentContext.performBlockAndWait {
            let all = NSFetchRequest(entityName: String(type))
            let accounts = try! concurrentContext.executeFetchRequest(all)
            for record in accounts {
                concurrentContext.deleteObject(record as! NSManagedObject)
            }
            try! concurrentContext.save()
        }
    }

}