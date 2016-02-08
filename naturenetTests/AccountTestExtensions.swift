//
//  AccountTestExtensions.swift
//  NatureNet
//
//  Created by Jason Maher on 2/8/16.
//
//

import Foundation

@testable import NatureNet

extension Account {

    /// Creates an account from random data optionally saving it to the context.
    ///
    /// - parameter save: should the instance be saved, defaults to `true`
    /// - returns: the inserted and saved instance
    static func random(save save: Bool = true) -> Account {
        let created = NNModel.insert(Account.self)
        created.uid = Random.int(0...10000)
        created.username = Random.alphanumeric();
        created.email = "testuser-\(created.uid)@nature-net.org"
        created.name = "Test User"
        created.created_at = Random.int()
        created.modified_at = Random.int()
        if save {
            try! created.save()
        }
        return created
    }

    /// Creates a data dictionary similar to what would be sent from the server with
    /// random values.
    ///
    /// - returns: the dictionary of random values.
    static func randomDictionary() -> [String: AnyObject] {
        let id = Random.int(0...10000)
        return [
            "id": id,
            "username": Random.alphanumeric(),
            "name": "Test User",
            "email": "testuser-\(id)@nature-net.org",
            "created_at": Random.int(),
            "modified_at": Random.int()
        ]
    }

    /// Converts this instance into a data dictionary similar to what would
    /// be sent from the server.
    ///
    /// - returns: the key value pairs of this account
    func toDictionary() -> [String: AnyObject] {
        return [
            "id": self.uid,
            "username": self.username,
            "name": self.name,
            "email": self.email,
            "created_at": self.created_at,
            "modified_at": self.modified_at
        ]
    }

}