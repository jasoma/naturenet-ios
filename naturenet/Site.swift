//
//  Site.swift
//  naturenet
//
//  Created by Jinyue Xia on 1/26/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import CoreData

@objc(Site)
class Site: NNModel {
    @NSManaged var site_description: String
    @NSManaged var image_url: String
    @NSManaged var name: String
    @NSManaged var kind: String
    
    // pull info from remote server
    class func doPullByNameFromServer(parseService: APIService, name: String) {
        let siteUrl = APIAdapter.api.getSiteLink(name)
        parseService.getResponse(NSStringFromClass(Site), url: siteUrl)
    }
    
    class func saveToCoreData(data: NSDictionary) -> Site {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let mSite =  SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Site), managedObjectConect: managedContext) as! Site
        mSite.parseJSON(data)
        mSite.commit()
        return mSite
    }
    
    // update data in core data
    override func updateToCoreData(data: NSDictionary) {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
//        var contexts = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Context), withPredicate: nil, managedObjectContext: managedContext) as! [Context]
//        for context in contexts {
//            managedContext.deleteObject(context)
//        }
        
        let contexts = data["contexts"] as! NSArray
        for tContext in contexts {
            let uid = tContext["id"] as! Int
            let predicate = NSPredicate(format: "uid = \(uid)")
            if let mContext =  SwiftCoreDataHelper.fetchEntitySingle(NSStringFromClass(Context), withPredicate: predicate, managedObjectContext: managedContext) as? Context {
                mContext.updateToCoreData(tContext as! NSDictionary)
//                mContext.site = self

            } else {
                let mContext =  SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Context), managedObjectConect: managedContext) as! Context
                mContext.parseContextJSON(tContext as! NSDictionary)
                mContext.site_uid = self.uid
                // mContext.site = self
                mContext.commit()
//                self.contexts.addObject(mContext)
            }

        }
        SwiftCoreDataHelper.saveManagedObjectContext(managedContext)

    }
    
    // parse site JSON data
    func parseJSON(data: NSDictionary) -> Site {
        self.created_at = NSNumber(unsignedLongLong: UInt64(NSDate().timeIntervalSince1970 * 1000))
        self.name = data["name"] as! String
        let contexts = data["contexts"] as! NSArray
        self.site_description = data["description"] as! String
        self.image_url = data["image_url"] as! String
        self.state = STATE.DOWNLOADED
        self.uid = data["id"] as! Int
        self.resovleContextData(contexts)
        // println("A new site " + self.toString() + " saved")
        return self
    }
    
    // save context
    func resovleContextData(contexts: NSArray) {
        if (contexts.count == 0) {
            return
        }
        
        for tContext in contexts {
            let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
            let mContext =  SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Context), managedObjectConect: managedContext) as! Context
            mContext.parseContextJSON(tContext as! NSDictionary)
            mContext.site_uid = self.uid
//            mContext.site = self
            mContext.commit()
//            self.contexts.addObject(mContext)
            SwiftCoreDataHelper.saveManagedObjectContext(managedContext)
            // println("A new context:{ " + mContext.toString() + " } saved!")
        }
    }
    
    // get contexts
    func getContexts() -> NSArray {
        let managedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        // let predicate = NSPredicate(format: "site = %@", self.objectID)
        let predicate = NSPredicate(format: "site_uid = \(self.uid)")
        let sitecontexts = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Context), withPredicate: predicate, managedObjectContext: managedContext)
        return sitecontexts
    }
    
    // get landmarks
    func getLandmarks() -> [Context] {
        let contexts = getContexts() as! [Context]
        var landmarks = [Context]()
        for context in contexts {
            if context.kind == "Landmark" {
                landmarks.append(context)
            }
        }
        return landmarks
    }
    
    // parse contexts json to an array contains a list of dictionary
    // @Deprecated
    func convertContextData(contexts: NSArray) -> [[String: AnyObject?]]  {
        var contextDictArrays: [[String: AnyObject?]] = []
        if (contexts.count == 0) {
            return contextDictArrays
        }
        
        for tContext in contexts {
            let contextUID = tContext["id"] as! Int
            var cDescription: String?
            if tContext["description"] != nil {
                cDescription = tContext["description"] as? String
            }
            
            var extras: String?
            if let ext = tContext["extras"] as? String {
                extras = ext as String
            }
            let title = tContext["title"] as! String
            let kind = tContext["kind"] as! String
            let contextDict: [String: AnyObject?]  = ["uid": contextUID, "description": cDescription, "title": title, "kind": kind, "extras": extras]
            contextDictArrays.append(contextDict)
        }
        
        // println(contextDictArrays)
        return contextDictArrays
    }

    func toString() -> String {
        return "name: \(name) uid: \(uid) created: \(created_at) state: \(state)"
    }

}
