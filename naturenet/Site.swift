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
    @NSManaged var contexts: NSArray
    
    // pull info from remote server
    class func doPullByNameFromServer(parseService: APIService, name: String) {
        var siteUrl = APIAdapter.api.getSiteLink(name)
        parseService.getResponse(NSStringFromClass(Site), url: siteUrl)
    }
    
    // save a new site in coredata
    // @Deprecated
    class func createInManagedObjectContext(name: String, uid: Int, description: String, imageURL: String) -> Site {
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let ent = NSEntityDescription.entityForName("Site", inManagedObjectContext: context)!
        let newSite = Site(entity: ent, insertIntoManagedObjectContext: context)
        newSite.created_at = NSDate().timeIntervalSince1970
        newSite.name = name
        newSite.uid = uid
        newSite.site_description = description
        newSite.image_url = imageURL
        newSite.state = STATE.DOWNLOADED
        context.save(nil)
        println("newSite is : \(newSite)" + "Site entity is: \(newSite.toString())")
        return newSite
    }
    
    // parse site JSON data
    func parseSiteJSON(data: NSDictionary) -> Site {
        self.created_at = NSDate().timeIntervalSince1970
        self.name = data["name"] as String
        var contexts = data["contexts"] as NSArray
        self.site_description = data["description"] as String
        self.image_url = data["image_url"] as String
        self.state = STATE.DOWNLOADED
        self.uid = data["id"] as Int
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
            var mContext =  SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Context), managedObjectConect: managedContext) as Context
            mContext.parseContextJSON(tContext as NSDictionary)
            mContext.site_uid = self.uid
            SwiftCoreDataHelper.saveManagedObjectContext(managedContext)
            mContext.commit()
            println("A new context:{ " + mContext.toString() + " } saved!")
        }
    }
    
    // get contexts
    func getContexts() -> NSArray {
        if self.contexts.count > 0 {
            return self.contexts
        } else {
            return NNModel.doPullAllByEntityFromCoreData(NSStringFromClass(Context))
        }
    }
    
    // parse contexts json to an array contains a list of dictionary
    // @Deprecated
    func convertContextData(contexts: NSArray) -> [[String: AnyObject?]]  {
        var contextDictArrays: [[String: AnyObject?]] = []
        if (contexts.count == 0) {
            return contextDictArrays
        }
        
        for tContext in contexts {
            var contextUID = tContext["id"] as Int
            var name = tContext["name"] as String
            var cDescription: String?
            if tContext["description"] != nil {
                cDescription = tContext["description"] as? String
            }
            
            var extras: String?
            if var ext = tContext["extras"] as? String {
                extras = ext as String
            }
            var title = tContext["title"] as String
            var kind = tContext["kind"] as String
            var contextDict: [String: AnyObject?]  = ["uid": contextUID, "description": cDescription, "title": title, "kind": kind, "extras": extras]
            contextDictArrays.append(contextDict)
        }
        
        // println(contextDictArrays)
        return contextDictArrays
    }

    func toString() -> String {
        var string = "name: \(name) uid: \(uid) created: \(created_at) state: \(state)"
        return string
    }
    
//    override func resolveDependencies() {
//        if (contexts.count > 0) {
//            for context in contexts {
//                if let tContext = context as? Context {
//                    tContext.state = STATE.DOWNLOADED
//                }
//            }
//        }
//    }

}
