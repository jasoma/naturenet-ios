//
//  ActivitiesTableViewController.swift
//  naturenet
//
//  Created by Jinyue Xia on 2/12/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit
import CoreData

class ActivitiesTableViewController: UITableViewController, APIControllerProtocol {

    var acesActivities: [Context] = [Context]()
    var nonAcesActivities: [Context] = [Context]()
    var cellActivities: [TableviewCellActivity] = [TableviewCellActivity] ()
    
    let ACESSITENAME = "aces"
    let BACKYARDSITENAME = "elsewhere"
    
    // UI
    @IBOutlet var tableview: UITableView!
    
    struct TableviewCellActivity {
        var cellSection: Int
        var cellIndexPath: NSIndexPath
        var isBirdActivity: Bool
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadActivities()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // self.refreshControl?.backgroundColor = UIColor.greenColor()
        self.refreshControl?.tintColor = UIColor.darkGrayColor()
        
        // do not set title in viewDidLoad, it causes a big gap on the top tableview after pull to refresh
        // self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: "refreshActivityList", forControlEvents: UIControlEvents.ValueChanged)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows: Int!
        if section == 0 {
            rows = acesActivities.count
        }
        if section == 1 {
            rows = nonAcesActivities.count
        }
        
        return rows
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var headerTitle: String!
        if section == 0 {
            headerTitle = "Activities in ACES"
        }
        if section == 1 {
            headerTitle = "Activities outside ACES"
        }
        return headerTitle
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("activitiesCell", forIndexPath: indexPath)
        var activityIconURL: String!
        let isJSONActivity: Bool = false
        
        if indexPath.section == 0 {
            let activity = self.acesActivities[indexPath.row] as Context
            cell.textLabel?.text = activity.title
            let birdsURLs = activity.extras as NSString
            
            // check the link is in a JSON String or not, if it is in a JSON object, get the value from "Icon" key
            if let
                data = birdsURLs.dataUsingEncoding(NSUTF8StringEncoding),
                json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary,
                _ = json["type"] as? String
            {
                activityIconURL = json["icon"] as! String
            } else {
                activityIconURL = birdsURLs as String
            }
            
            let cellActivity: TableviewCellActivity = TableviewCellActivity(
                cellSection: indexPath.section,
                cellIndexPath: indexPath,
                isBirdActivity: isJSONActivity)
            self.cellActivities.append(cellActivity)
        }
        
        if indexPath.section == 1 {
            let activity = self.nonAcesActivities[indexPath.row] as Context
            activityIconURL = activity.extras
            
            if let
                data = activityIconURL.dataUsingEncoding(NSUTF8StringEncoding),
                json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary
            {
                activityIconURL = json["Icon"] as! String
                cell.textLabel?.text = activity.title
            }
        }
        
        loadImageFromWeb(ImageHelper.createThumbCloudinaryLink(activityIconURL, width: 128, height: 128), cell: cell, index: indexPath.row)

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if cellActivities[indexPath.row].isBirdActivity {
                self.performSegueWithIdentifier("birdActivity", sender: indexPath)
            } else {
                self.performSegueWithIdentifier("activityDetail", sender: indexPath)
            }
        }
        if indexPath.section == 1 {
            self.performSegueWithIdentifier("activityDetail", sender: indexPath)
        }

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "activityDetail" {
            let destinationVC = segue.destinationViewController as! ActivityDetailTableViewController
            // if passed from a cell
            if let indexPath = sender as? NSIndexPath {
                var selectedActivity: Context!
                if indexPath.section == 0 {
                    selectedActivity = acesActivities[indexPath.row]
                }
                
                if indexPath.section == 1 {
                    selectedActivity = nonAcesActivities[indexPath.row]
                }
                
                destinationVC.activity = selectedActivity
            }
        }
        
        if segue.identifier == "birdActivity" {
            let destinationVC = segue.destinationViewController as! BirdActivityTableViewController
            if let indexPath = sender as? NSIndexPath {
                let activity = self.acesActivities[indexPath.row] as Context
                // destinationVC.activity = activity
                destinationVC.activityDescription = activity.context_description
                destinationVC.navigationItem.title = activity.title
                let birdsURLs = activity.extras as NSString
                
                if let
                    data = birdsURLs.dataUsingEncoding(NSUTF8StringEncoding),
                    json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary
                {
                    destinationVC.activityThumbURL = json["Icon"] as! String
                    if let birdsJSON = json["Birds"] as? [NSDictionary] {
                        let birds = self.convertBirdJSONToBirds(birdsJSON)
                        destinationVC.birds = birds
                    }
                    destinationVC.activity = activity
                }
            }
        }

    }
    
    // load activities for this tableview
    private func loadActivities() {
        if let acesSite = Session.getSiteByName(ACESSITENAME) {
            self.acesActivities = Session.getActiveContextsBySite("Activity", site: acesSite)
        }
        
        if let site = Session.getSiteByName(BACKYARDSITENAME) {
            self.nonAcesActivities = Session.getActiveContextsBySite("Activity", site: site)
        }
    }
    
    private func loadImageFromWeb(iconURL: String, cell: UITableViewCell, index: Int ) {
        if let url = NSURL(string: iconURL) {
            let urlRequest = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue(), completionHandler: {
                response, data, error in
                if error != nil {
                    let image = UIImage(named: "networkerror")
                    cell.imageView?.image = image
                    
                } else {
                    let image = UIImage(data: data!)
                    cell.imageView?.image = image
                }
            })
        }
      
    }
    
    // give a JSON output an array of BirdCount (defined in BirdCountingTableViewController)
    private func convertBirdJSONToBirds(birdsJSON: [NSDictionary]) -> [BirdActivityTableViewController.BirdCount] {
        var birds: [BirdActivityTableViewController.BirdCount] = []
        for birdJSON in birdsJSON {
            let bird = BirdActivityTableViewController.BirdCount()
            if let name = birdJSON["name"] as? String {
                bird.name = name
            }
            if let url = birdJSON["image"] as? String {
                bird.thumbnailURL = ImageHelper.createThumbCloudinaryLink(url, width: 200, height: 200)
            }
            bird.countNumber = "0"
            birds.append(bird)
        }
        
        return birds
    }
    
    // pull to refresh
    @IBAction func refreshActivityList() {
        let parseService = APIService()
        parseService.delegate = self
        Site.doPullByNameFromServer(parseService, name: "aces")
        Site.doPullByNameFromServer(parseService, name: "elsewhere")
    }
    
    // after getting data from server
    func didReceiveResults(from: String, sourceData: NNModel?, response: NSDictionary) -> Void {
        dispatch_async(dispatch_get_main_queue(), {
            let status = response["status_code"] as! Int
            if (status == 400) {
//                var errorMessage = "We didn't recognize your NatureNet Name or Password"
                return
            }
            
            // 600 is self defined error code on the phone's side
            if (status == 600) {
//                var errorMessage = "Internet seems not working"
                // self.createAlert(errorMessage)
                return
            }
            
            if from == "Site" {
                let data = response["data"] as! NSDictionary!
                let model = data["_model_"] as! String
                self.handleSiteData(data)
            }
            // reload the data for tableView
            self.loadActivities()
            self.tableView.reloadData()
//            self.tableView.beginUpdates()
//            self.tableView.endUpdates()
            self.refreshControl?.endRefreshing()
        })
    }
    
    // !!!if site exists, no update, should check modified date is changed!! but no modified date returned from API
    func handleSiteData(data: NSDictionary) {
        var sitename = data["name"] as! String
        let predicate = NSPredicate(format: "name = %@", sitename)
        let exisitingSite = NNModel.fetechEntitySingle(NSStringFromClass(Site), predicate: predicate) as? Site
        if exisitingSite != nil {
            // should check if modified date is changed here!! but no modified date returned from API
            exisitingSite!.updateToCoreData(data)
        } else {
//            self.site = Site.saveToCoreData(data)
        }
    }



}
