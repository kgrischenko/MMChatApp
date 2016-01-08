//
//  HomeViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 12/29/15.
//  Copyright © 2015 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class HomeViewController: UITableViewController, ContactsViewControllerDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    var summaryResponses : [MMXChannelSummaryResponse] = []
    var filteredSummaryResponses : [MMXChannelSummaryResponse] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        var title = String()
        if let user = MMUser.currentUser() {
            title = "\(user.firstName ?? "") \(user.lastName ?? "")"
        }
        self.title = title

        if let revealVC = self.revealViewController() {
            self.navigationItem.leftBarButtonItem!.target = revealVC
            self.navigationItem.leftBarButtonItem!.action = "revealToggle:"
            self.view.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
        
        // Add search bar
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        tableView.reloadData()
        
        // Get all channels the current user is subscribed to
        MMXChannel.subscribedChannelsWithSuccess({ (channels) -> Void in
            // get summaries
            let channelsSet = Set(channels)
            MMXChannel.channelSummary(channelsSet, numberOfMessages: 5, numberOfSubcribers: 5, success: { [weak self] summaryResponses in
                self?.summaryResponses = summaryResponses
                self?.tableView.reloadData()
            }, failure: { error in
                print(error)
            })
        }) { error in
            print(error)
        }
        
        let summary = MMXChannelSummaryResponse()
        summaryResponses.append(summary)
    }
    
    // MARK: - Helpers
    
    func filterContentForSearchText(searchText: String) {
//        filteredMessages = messages.filter { message in
//            return message.name.lowercaseString.containsString(searchText.lowercaseString)
//        }
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredSummaryResponses.count
        }
        return summaryResponses.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SummaryResponseCell", forIndexPath: indexPath) as! SummaryResponseCell
//        let candy: Candy
//        if searchController.active && searchController.searchBar.text != "" {
//            candy = filteredCandies[indexPath.row]
//        } else {
//            candy = candies[indexPath.row]
//        }
        cell.summaryResponse = summaryResponses[indexPath.row]
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        //FIXME: isLastPersonInChat
        let isLastPersonInChat = indexPath.section % 2 == 0
        if isLastPersonInChat {
            let delete = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
                // Delete the row from the data source
                //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            delete.backgroundColor = UIColor.redColor()
            return [delete]
        } else {
            let leave = UITableViewRowAction(style: .Normal, title: "Leave") { action, index in
            }
            leave.backgroundColor = UIColor.orangeColor()
            return [leave]
        }
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
 
    }
    
    //MARK: - ContactsViewControllerDelegate
    
    func contactsControllerDidFinish(with selectedUsers: [MMUser]) {
        if let chatVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as? ChatViewController {
            chatVC.recipients = selectedUsers
            self.navigationController?.pushViewController(chatVC, animated: false)
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showChatFromChannelSummary" {
            if let chatVC = segue.destinationViewController as? ChatViewController, let cell = sender as? SummaryResponseCell {
                if let recipients = cell.summaryResponse.subscribers as? [MMUser] {
                    chatVC.recipients = recipients
                }
            }
        } else if segue.identifier == "showContactsSelector" {
            if let navigationVC = segue.destinationViewController as? UINavigationController {
                if let contactsVC = navigationVC.topViewController as? ContactsViewController {
                    contactsVC.delegate = self
                }
            }
        }
    }

}

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

