//
//  DetailsViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/5/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class DetailsViewController: UITableViewController, ContactsViewControllerDelegate {
    
    var recipients: [MMUser] = []

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipients.count + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecipientsCellIdentifier", forIndexPath: indexPath)

        if indexPath.row == recipients.count {
            cell.textLabel?.attributedText = NSAttributedString(string: "+ Add Contact",
                                                            attributes: [NSForegroundColorAttributeName : self.view.tintColor,
                                                                         NSFontAttributeName : UIFont.systemFontOfSize((cell.textLabel?.font.pointSize)!)])
        } else {
            let attributes = [NSFontAttributeName : UIFont.boldSystemFontOfSize((cell.textLabel?.font.pointSize)!),
                              NSForegroundColorAttributeName : UIColor.blackColor()]
            var title = NSAttributedString()
            let user = recipients[indexPath.row]
            if let lastName = user.lastName where lastName.isEmpty == false {
                title = NSAttributedString(string: lastName, attributes: attributes)
            }
            if let firstName = user.firstName where firstName.isEmpty == false {
                if let lastName = user.lastName where lastName.isEmpty == false{
                    let firstPart = NSMutableAttributedString(string: "\(firstName) ")
                    firstPart.appendAttributedString(title)
                    title = firstPart
                } else {
                    title = NSAttributedString(string: firstName, attributes: attributes)
                }
            }
            
            cell.textLabel?.attributedText = title
        }

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == recipients.count {
            // Show contact selector
            if let navigationVC = self.storyboard?.instantiateViewControllerWithIdentifier("ContactsNavigationController") as? UINavigationController {
                if let contactsVC = navigationVC.topViewController as? ContactsViewController {
                    contactsVC.delegate = self
                    self.presentViewController(navigationVC, animated: true, completion: nil)
                }
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //MARK: - ContactsViewControllerDelegate
    
    func contactsControllerDidFinish(with selectedUsers: [MMUser]) {
        self.navigationController?.popViewControllerAnimated(false)
        if let chatVC = self.navigationController?.topViewController as? ChatViewController {
//            chatVC.recipients = selectedUsers
        }
    }
    
}
