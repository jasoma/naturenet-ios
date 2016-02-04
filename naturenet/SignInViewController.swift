//
//  SignIn.swift
//  NatureNet
//
//  Created by Jinyue Xia on 1/1/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit
import CoreData

class SignInViewController: UIViewController, APIControllerProtocol, UITextFieldDelegate, UITableViewDelegate {
    var signInIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var site: Site?
    var account: Account?
    
    let signFormLabels = ["Username", "Password"]
    let signFormImageNames = ["user", "padlock"]
    let signFromPlaceholder = ["Enter username", "Enter password"]

    var textFieldUname: UITextField!
    var textFieldUpass: UITextField!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var signFormTableView: UITableView!
    
    var parseService = APIService()

    //----------------------------------------------------------------------------------------------------------------------
    // IBActions/Functions with textfields
    //----------------------------------------------------------------------------------------------------------------------
    @IBAction func textFieldDoneEditing(sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    @IBAction func backgroundTap(sender: UIControl) {
        if textFieldUpass != nil && textFieldUname != nil {
            textFieldUname.resignFirstResponder()
            textFieldUpass.resignFirstResponder()
        }
    }
    
    @IBAction func usernameTextFieldDidChange(sender: UITextField) {
        if !textFieldUname.text!.isEmpty && !textFieldUpass.text!.isEmpty {
            self.signButton.enabled = true
            self.signButton.alpha = 1.0
        }
        if textFieldUname.text!.isEmpty || textFieldUpass.text!.isEmpty {
            self.signButton.enabled = false
            self.signButton.alpha = 0.7
            
        }
    }
    
    @IBAction func passTextFieldDidChange(sender: UITextField) {
        if !textFieldUname.text!.isEmpty && !textFieldUpass.text!.isEmpty {
            self.signButton.enabled = true
            self.signButton.alpha = 1.0
        }
        if textFieldUname.text!.isEmpty || textFieldUpass.text!.isEmpty {
            self.signButton.enabled = false
            self.signButton.alpha = 0.7
        }
    }
    
    @IBAction func btnSignIn() {
        textFieldUname.resignFirstResponder()
        textFieldUpass.resignFirstResponder()
        // should never be called
        if textFieldUname.text!.isEmpty || textFieldUpass.text!.isEmpty {
            self.signButton.enabled = false
            self.signButton.alpha = 0.7
            self.showFailMessage("username or password cannot be empty")
            return
        }
        parseService.delegate = self
        createIndicator()
        Site.doPullByNameFromServer(parseService, name: "elsewhere")
        Site.doPullByNameFromServer(parseService, name: "aces")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textFieldUname.text!.isEmpty || textFieldUpass.text!.isEmpty {
            self.signButton.enabled = false
            self.signButton.alpha = 0.7
        }
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        self.alertLabel.hidden = true
        if textFieldUname.text!.isEmpty || textFieldUpass.text!.isEmpty {
            self.signButton.enabled = false
            self.signButton.alpha = 0.7
        }
    }
    
    // password textfield delegate, examine length not exceed 4
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var result = true
        let prospectiveText = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == textFieldUpass {
            if string.characters.count > 0 {
                let disallowedCharacterSet = NSCharacterSet(charactersInString: "0123456789").invertedSet
                let replacementStringIsLegal = string.rangeOfCharacterFromSet(disallowedCharacterSet) == nil
                let resultingStringLengthIsLegal = prospectiveText.characters.count <= 4
                result = replacementStringIsLegal && resultingStringLengthIsLegal
            }
        }
        return result
    }

    //----------------------------------------------------------------------------------------------------------------------
    // TableView for sign in form
    //----------------------------------------------------------------------------------------------------------------------
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellNib = UINib(nibName: "LogInTableViewCell", bundle: NSBundle.mainBundle())
        tableView.registerNib(cellNib, forCellReuseIdentifier: "inputFormCell")
        let cell = tableView.dequeueReusableCellWithIdentifier("inputFormCell", forIndexPath: indexPath) as! LogInTableViewCell
        cell.formItemImage.image = UIImage(named: signFormImageNames[indexPath.row])
        cell.formInputTextField.placeholder = signFromPlaceholder[indexPath.row]
        cell.formInputTextField.addTarget(self, action: "textFieldDidBeginEditing:", forControlEvents: UIControlEvents.EditingDidBegin)
        cell.formInputTextField.addTarget(self, action: "textFieldDoneEditing:", forControlEvents: UIControlEvents.EditingDidEnd)

        if indexPath.row == 0 {
            self.textFieldUname = cell.formInputTextField
            self.textFieldUname.addTarget(self, action: "usernameTextFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        } else {
            self.textFieldUpass = cell.formInputTextField
            self.textFieldUpass.addTarget(self, action: "passTextFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            self.textFieldUpass.delegate = self
            self.textFieldUpass.keyboardType = UIKeyboardType.NumberPad
            self.textFieldUpass.secureTextEntry = true
        }
            
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        } else {
            // Fallback on earlier versions
        }
        cell.separatorInset = UIEdgeInsetsZero
        if #available(iOS 8.0, *) {
            cell.preservesSuperviewLayoutMargins = false
        } else {
            // Fallback on earlier versions
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    
    // after getting data from server
    func didReceiveResults(from: String, sourceData: NNModel?, response: NSDictionary) -> Void {
        dispatch_async(dispatch_get_main_queue(), {
            let status = response["status_code"] as! Int
            var errorMessage = "Loading..."
            if (status == 400) {
                if from == "Account" {
                    errorMessage = "We didn't recognize your NatureNet Name or Password"
                }
                self.showFailMessage(errorMessage)
                self.pauseIndicator()
                return
            }
            
            // 600 is self defined error code on the phone's side
            if (status == 600) {
                let errorMessage = "Internet seems not working"
                // self.createAlert(errorMessage)
                self.showFailMessage(errorMessage)
                self.pauseIndicator()
                return
            }
            
            // println("received results from \(from)")
            if from == "Account" {
                // var data = response["data"] as NSDictionary!
                let data = response["data"] as! NSDictionary!
                self.handleUserData(data)
            }
            
            if from == "Site" {
                let data = response["data"] as! NSDictionary!
                self.handleSiteData(data)
            }
            
            if from == "Note" {
                // response["data"] is an array of notes
                let data = response["data"] as! NSArray!
                self.handleNoteData(data)
                self.pauseIndicator()
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        })
    }
    
    // parse account info and save
    func handleUserData(data: NSDictionary) {
        let username = data["username"] as! String
        let predicate = NSPredicate(format: "username = %@", username)
        
        if let existingAccount = NNModel.fetechEntitySingle(NSStringFromClass(Account), predicate: predicate) as? Account {
            existingAccount.updateToCoreData(data)
            existingAccount.commit()
            self.account = existingAccount
        } else {
            self.account = Account.saveToCoreData(data)
        }

        // the account update/save operation might fail
        if let account = self.account {
            Session.signIn(account, site: self.site!)
            account.pullnotes(parseService)
        } else {
            self.showFailMessage("There was an error signing in to your account")
            self.pauseIndicator()
        }
    }
    
    // parse site info and save
    // !!!if site exists, no update, should check modified date is changed!! but no modified date returned from API
    func handleSiteData(data: NSDictionary) {
        let sitename = data["name"] as! String
        
        let predicate = NSPredicate(format: "name = %@", sitename)
        let exisitingSite = NNModel.fetechEntitySingle(NSStringFromClass(Site), predicate: predicate) as? Site
        if exisitingSite != nil {
            // println("You have aces site in core data: "  + exisitingSite!.toString())
            // should check if modified date is changed here!! but no modified date returned from API
            self.site = exisitingSite
            self.site?.updateToCoreData(data)
        } else {
            self.site = Site.saveToCoreData(data)
        }
        let inputUser = textFieldUname.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if !SignInViewController.hasWhiteSpace(inputUser) {
            Account.doPullByNameFromServer(parseService, name: inputUser)
        } else {
            let errorMessage = "Username is not valid"
            self.showFailMessage(errorMessage)
            self.pauseIndicator()
        }
    }
    
       
    // save notes
    func handleNoteData(notes: NSArray) {
        // println("notes are: \(notes)")
        if (notes.count == 0) {
            return
        }
        
        for mNote in notes {
            let serverNote = mNote as! NSDictionary
            var localNote: Note?
            let noteUID = serverNote["id"] as! Int
            let predicate = NSPredicate(format: "uid = \(noteUID)")
            let nsManagedContext: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
            let items = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Note), withPredicate: predicate, managedObjectContext: nsManagedContext) as! [Note]

            if (items.count > 0) {
                localNote = items[0]
            }
            
            if localNote != nil {
                if localNote!.modified_at != serverNote["modified_at"] as! NSNumber {
                    localNote!.updateNote(serverNote)
                }
            } else {
                // save mNote as a new note entry
                Note.saveToCoreData(mNote as! NSDictionary)
            }
        }
    }

    // create a loading indicator for sign in
    func createIndicator() {
        signInIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
        signInIndicator.center = self.view.center
        signInIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(signInIndicator)
        signInIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }

    func pauseIndicator() {
        signInIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
    
    // show sign in failed message
    func showFailMessage(message: String) {
        self.alertLabel.text = message
        self.alertLabel.hidden = false
    }
    
    // create an alert
    func createAlert(message: String) {
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: "Sign In Failed", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
        }
    }
    
    // trim whitespace after a string and check the string has a whitespace
    class func hasWhiteSpace(string: String) -> Bool {
        var hasSpace = false
        let whitespace = NSCharacterSet.whitespaceCharacterSet()
        if let _ = string.rangeOfCharacterFromSet(whitespace) {
            hasSpace = true
        }
        return hasSpace
    }
    
}
