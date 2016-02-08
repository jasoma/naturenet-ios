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
        let all = NSFetchRequest(entityName: String(type))
        let accounts = try! self.context.executeFetchRequest(all)
        for record in accounts {
            context.deleteObject(record as! NSManagedObject)
        }
        try! self.context.save()
    }

}