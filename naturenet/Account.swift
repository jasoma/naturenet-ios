//
//  ManagedAccount.swift
//  naturenet
//
//  Created by Jinyue Xia on 1/15/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON

@objc(Account)
class Account: NNModel {

    @NSManaged var email: String
    @NSManaged var name: String
    @NSManaged var password: String
    @NSManaged var username: String
    let nsManagedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext

    // pull info from remote server
    class func doPullByNameFromServer(parseService: APIService, name: String) {
        let accountUrl = APIAdapter.api.getAccountLink(name)
        parseService.getResponse(NSStringFromClass(Account), url: accountUrl)
    }
    
    /// Updates this account instance with values from a dictionary, it is expected that the
    /// keys in the dictionary have the same names as the properties of the class with the
    /// exception that `Account#uid` is read from the value of the key `id`.
    ///
    /// - parameter data: the dictionary to read values from.
    /// - returns: the created account or nil if the dictionary contains incomplete data or
    ///            a values type does not match.
    func updateWithData(data: NSDictionary) throws {
        if let
            uid = data["id"] as? Int,
            username = data["username"] as? String {
                self.uid = uid
                self.username = username
                if let
                    name = data["name"] as? String,
                    created_at = data["created_at"] as? NSNumber,
                    modified_at = data["modified_at"] as?   NSNumber {
                        self.name = name
                        self.created_at = created_at
                        self.modified_at = modified_at
                    }
        } else {
            throw ModelErrors.IncompleteData(data)
        }
    }
    
    // update data in core data
    override func updateToCoreData(data: NSDictionary) {
        do {
            try updateWithData(data)
            SwiftCoreDataHelper.saveManagedObjectContext(self.nsManagedContext)
        } catch {
            // TODO: it would be nicer to let the error propagate so the controller can present something to
            //       the user, requires modifying the base class.
            print("Update failed: \(error)")
        }
    }
    
    // save a new account in core data
    class func saveToCoreData(mAccount: NSDictionary) -> Account? {
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let account =  SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Account), managedObjectConect: context) as! Account
        do {
            try account.updateWithData(mAccount)
            account.commit()
            return account
        } catch {
            print("Failed to save an account: \(error)")
            return nil
        }
    }
    
    // push a new user to remote server as HTTP post
    // returned JSON will be sent to apiService's delegate: ObservationsController
    override func doPushNew(apiService: APIService) -> Void {
        let url = APIAdapter.api.getCreateAccountLink(self.username)
        let params = ["name": self.name, "password": self.password, "email": self.email] as Dictionary<String, Any>
        apiService.post(NSStringFromClass(Account), sourceData: self,  params: params, url: url)
    }
    
    func getNotes() -> [Note] {
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let predicate = NSPredicate(format: "account = %@", self.objectID)
        let results = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Note), withPredicate: predicate, managedObjectContext: context) as! [Note]
        return results
    }
    
    // get notes of this user by activity
    func getNotesByActivity(activity: Context) -> [Note]{
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let predicate = NSPredicate(format: "account = %@", self.objectID)
        let predicate2 = NSPredicate(format: "context = %@", activity.objectID)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
        let results = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Note), withPredicate: compound, managedObjectContext: context) as! [Note]
        
        // println("got \(results.count) results")
        return results
        
    }
    
    func saveNote(selectedActivity: Context, content: String?, longitude: NSNumber?, latitude: NSNumber?) -> Note {
        let nsManagedContext = SwiftCoreDataHelper.nsManagedObjectContext
        let mNote = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Note), managedObjectConect: nsManagedContext) as! Note
        if longitude != nil && latitude != nil {
            mNote.longitude = longitude!
            mNote.latitude = latitude!
        }
        mNote.account = self
        mNote.kind = "FieldNote"
        mNote.state = NNModel.STATE.NEW
        if let desc = content {
            mNote.content = desc
        }
        mNote.context = selectedActivity
        
        return mNote
    }
    
    // pull this user's note
    func pullnotes(parseService: APIService) {
        let accountUrl = APIAdapter.api.getAccountNotesLink(self.username)
        print("api service is from \(NSStringFromClass(Note)) url is: \(accountUrl) " )
        parseService.getResponse(NSStringFromClass(Note), url: accountUrl)
    }

    override var description: String {
        return "Account[username: \(username), uid: \(uid)  modified: \(modified_at) name: \(name) state: \(state)]"
    }

}
