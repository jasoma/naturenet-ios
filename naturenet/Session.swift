//
//  Session.swift
//  naturenet
//
//  Created by Jinyue Xia on 1/25/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import CoreData

@objc(Session)
class Session: NSManagedObject {

    @NSManaged var account_id: NSNumber
    @NSManaged var site_id: NSNumber
    @NSManaged var account: Account
    @NSManaged var site: Site
    
    class var sharedInstance: Session {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        struct Singleton {
//            static let instance = SwiftCoreDataHelper.getEntityByModelName(NSStringFromClass(Session), managedObjectContext: managedContext) as Session
             static let instance = Session()
        }
        return Singleton.instance
    }
    
    class func isSignedIn() -> Bool {
        var isSigned: Bool = false;
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var results: NSArray = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: context)
        println("session retrieved \(results)")
        if results.count > 0 {
            var session = results[0] as Session
            if session.account_id.integerValue > 0 {
                isSigned = true
            }
        }
        return isSigned
    }
    
    class func signIn(accountID: Int, siteID: Int) {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var session = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Session), managedObjectConect: managedContext) as Session
        session.account_id = accountID
        session.site_id = siteID
        SwiftCoreDataHelper.saveManagedObjectContext(managedContext)
    }
    
    class func signIn(account: Account, site: Site) {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var sessionAccounts:[Session] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: managedContext) as [Session]
        if sessionAccounts.count > 0 {
            var session = sessionAccounts[0]
            self.setValue(account, forKey: "account")
            self.setValue(site, forKey: "context")
        } else {
            var session = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Session), managedObjectConect: managedContext) as Session
            session.account = account
            session.site = site
            session.account_id = account.uid
            session.site_id = site.uid
        }
        SwiftCoreDataHelper.saveManagedObjectContext(managedContext)

    }
    
    class func signOut() {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var session = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Session), managedObjectConect: managedContext) as Session
        session.account_id = -1
        session.site_id = -1
        SwiftCoreDataHelper.saveManagedObjectContext(managedContext)
    }
    
    class func getAccount() -> Account? {
        var account: Account?
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var sessionAccounts:[Session] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: managedContext) as [Session]
        if sessionAccounts.count > 0 {
            var session = sessionAccounts[0]
            account = session.account
        }
        return account
    }
    
  
}
