//
//  ObservationDetailController.swift
//  naturenet
//
//  Created by Jinyue Xia on 2/3/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit

class ObservationDetailController: UIViewController, UITableViewDelegate {

    // UI Outlets
    @IBOutlet weak var noteImageView: UIImageView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var detailTableView: UITableView!
    // data
    var receivedCellData: ObservationCell?
    var noteMedia: Media?
    var note: Note?
    var activities = [Context]()
    var landmarks = [Context]()
    
    // tableview data
    var titles = ["Description", "Activity", "Location"]
    var details = ["Description", "Free Observation", "Other"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadData()
        self.detailTableView.reloadData()
        imageLoadingIndicator.startAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "profilecell")
        let cell = tableView.dequeueReusableCellWithIdentifier("editObsCell", forIndexPath: indexPath) as EditObsTableViewCell
        cell.editCellTitle!.text = titles[indexPath.row]
        cell.editCellDetail!.text = details[indexPath.row]
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editObsToDescription" {
            let destinationVC = segue.destinationViewController as NoteDescriptionViewController
            destinationVC.noteContent = details[0]
        }
        if segue.identifier == "selectObsActivitySeg" {
            let destinationVC = segue.destinationViewController as NoteActivitySelectionViewController
            destinationVC.activities = self.activities
            destinationVC.selectedActivityTitle = details[1]
        }

    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0 :
            self.performSegueWithIdentifier("editObsToDescription", sender: self)
        case 1 :
            self.performSegueWithIdentifier("selectObsActivitySeg", sender: self)
        case 2 :
            self.performSegueWithIdentifier("selectObsLocationSeg", sender: self)
        default:
            return
        }
    }
    
    @IBAction func passedDescription(segue:UIStoryboardSegue) {
        let noteDescriptionVC = segue.sourceViewController as NoteDescriptionViewController
        if let desc = noteDescriptionVC.noteContent {
            details[0] = desc
        }
        self.navigationController?.popViewControllerAnimated(true)
        self.detailTableView.reloadData()
    }
    
    @IBAction func passedActivitySelection(segue:UIStoryboardSegue) {
        let noteActivitySelectionVC = segue.sourceViewController as NoteActivitySelectionViewController
        if let activityTitle = noteActivitySelectionVC.selectedActivityTitle {
            details[1] = activityTitle
        }
        self.navigationController?.popViewControllerAnimated(true)
        self.detailTableView.reloadData()
    }
    
    func loadData() {
        if let site: Site = Session.getSite() {
            let siteContexts = site.getContexts()
            for sContext in siteContexts {
                let context = sContext as Context
                if context.kind == "Landmark" {
                    self.landmarks.append(context)
                }
                if context.kind == "Activity" {
                    self.activities.append(context)
                }
            }
        }
        
        var mediaUID = receivedCellData!.uid as Int
        self.noteMedia = NNModel.doPullByUIDFromCoreData(NSStringFromClass(Media), uid: mediaUID) as Media?
        self.note = noteMedia?.getNote()
        details[0] = note!.content
        var noteActivity = note!.context
        details[1] = noteActivity.title

        loadFullImage(noteMedia!.url)
        // println(" note info is: \(self.noteMedia!.getNote().toString()) media info: \(noteMedia!.toString()) ")
    }
    
    func setUI() {
        if let desc = self.note?.content {
//            descriptionView.text = desc
        }
    
    }
    
    func loadFullImage(url: String) {
        var nsurl: NSURL = NSURL(string: url)!
        let urlRequest = NSURLRequest(URL: nsurl)
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue(), completionHandler: {
            response, data, error in
            if error != nil {
                
            } else {
                let image = UIImage(data: data)
                self.noteImageView.image = image
                self.imageLoadingIndicator.stopAnimating()
                self.imageLoadingIndicator.removeFromSuperview()
            }
        })
        
    }


}
