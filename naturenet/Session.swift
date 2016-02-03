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
        struct Singleton {
             static let instance = Session()
        }
        return Singleton.instance
    }
    
    class func isSignedIn() -> Bool {
        var isSigned: Bool = false;
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let results: NSArray = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: context)
        // println("session retrieved \(results)")
        if results.count > 0 {
            let session = results[0] as! Session
            if session.account.uid.integerValue > 0 {
                isSigned = true
            }
        }
        return isSigned
    }
    
    class func signIn(accountID: Int, siteID: Int) {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let session = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Session), managedObjectConect: managedContext) as! Session
        session.account_id = accountID
        session.site_id = siteID
        SwiftCoreDataHelper.saveManagedObjectContext(managedContext)
    }
    
    class func signIn(account: Account, site: Site) {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var sessionAccounts:[Session] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: managedContext) as! [Session]
        if sessionAccounts.count > 0 {
            let session = sessionAccounts[0]
            session.setValue(account, forKey: "account")
            session.setValue(site, forKey: "site")
            session.account_id = account.uid
            session.site_id = site.uid
        } else {
            let session = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Session), managedObjectConect: managedContext) as! Session
            session.account = account
            session.site = site
            session.account_id = account.uid
            session.site_id = site.uid
        }
        SwiftCoreDataHelper.saveManagedObjectContext(managedContext)

    }
    
    class func signOut() {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var sessionAccounts:[Session] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: managedContext) as! [Session]
        if sessionAccounts.count > 0 {
            let session = sessionAccounts[0]
            session.setValue(nil, forKey: "account")
            session.setValue(nil, forKey: "site")
            session.setValue(0, forKey: "account_id")
            session.setValue(0, forKey: "site_id")
        }
        SwiftCoreDataHelper.saveManagedObjectContext(managedContext)
    }
    
    class func getAccount() -> Account? {
        var account: Account?
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var sessionAccounts:[Session] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: managedContext) as! [Session]
        if sessionAccounts.count > 0 {
            let session = sessionAccounts[0]
            account = session.account
        }
        return account
    }
    
    class func getSite() -> Site? {
        var site: Site?
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var sessions:[Session] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Session), withPredicate: nil, managedObjectContext: managedContext) as! [Session]
        if sessions.count > 0 {
            let session = sessions[0]
            site = session.site
        }
        return site
    }
    
    class func getSiteByName(name: String) -> Site? {
        var site: Site?
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let sites:[Site] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Site), withPredicate: nil, managedObjectContext: managedContext) as! [Site]
        if sites.count > 0 {
            for s in sites {
                if s.name == name {
                    site = s
                }
            }
        }
        return site
    }
    
    class func getLandmarks() -> [Context] {
        var landmarks: [Context] = []
        if let site: Site = Session.getSite() {
            let siteContexts = site.getContexts()
            for sContext in siteContexts {
                let context = sContext as! Context
                if context.kind == "Landmark" {
                    landmarks.append(context)
                }
            }
        }
        
        return landmarks
    }
    
    // type can be "Landmark" or "Activity"
    class func getContexts(type: String) -> [Context] {
        var contexts: [Context] = []
        if let site: Site = Session.getSite() {
            let siteContexts = site.getContexts()
            for sContext in siteContexts {
                let context = sContext as! Context
                if context.kind == type {
                    contexts.append(context)
                }
            }
        }
        
        return contexts
    }
    
    // type can be "Landmark" or "Activity"
    class func getContexts(type: String, site: Site) -> [Context] {
        var contexts: [Context] = []
        let siteContexts = site.getContexts()
        for sContext in siteContexts {
            let context = sContext as! Context
            if context.kind == type {
                contexts.append(context)
            }
        }
        return contexts
    }
    
    // type can be "Landmark" or "Activity"
    // only returns active contexts
    class func getActiveContextsBySite(type: String, site: Site?) -> [Context] {
        var contexts: [Context] = []

        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let predicate = NSPredicate(format: "kind = %@", type)
        let activities:[Context] = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Context), withPredicate: predicate, managedObjectContext: managedContext) as! [Context]
        for activity in activities {
            if activity.kind == type {
                let extras = activity.extras as NSString
                
                if let
                    data = extras.dataUsingEncoding(NSUTF8StringEncoding),
                    json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary,
                    active = json["active"] as? Bool
                    where active
                {
                    if site != nil {
                        // it is risky here, choose activity name or uid
                        if activity.site_uid == site!.uid {
                            contexts.append(activity)
                        }
                    } else {
                        contexts.append(activity)
                    }
                }
            }
        }
        return contexts
    }
    
}
