//
//  ContactsViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/5/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class ContactsViewController: UITableViewController {
    
    var users : [MMUser] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let searchQuery = "userName:*"
        MMUser.searchUsers(searchQuery, limit: 100, offset: 0, sort: "userName:asc", success: { [weak self] users in
            self?.users = users
            self?.tableView.reloadData()
        }, failure: { error in
            print("[ERROR]: \(error.localizedDescription)")
        })
    }
    
    @IBAction func cancelAction() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func nextAction() {
        if let vc = self.presentingViewController {
            print("\(vc)\n")
        }
        if let vc = self.parentViewController {
            print("\(vc)\n")
        }
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }

    // MARK: - Table view data source

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 0
//    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
//    - (void)createAlphabetArray {
//    NSMutableArray *tempFirstLetterArray = [[NSMutableArray alloc] init];
//    for (int i = 0; i < [dataArray count]; i++) {
//    NSString *letterString = [[dataArray objectAtIndex:i] substringToIndex:1];
//    if (![tempFirstLetterArray containsObject:letterString]) {
//    [tempFirstLetterArray addObject:letterString];
//    }
//    }
//    alphabetsArray = tempFirstLetterArray;
//    [tempFirstLetterArray release];
//    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UserCellIdentifier", forIndexPath: indexPath)

        cell.textLabel?.text = users[indexPath.row].userName

        return cell
    }

       /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
