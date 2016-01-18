//
//  HomeViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 12/29/15.
//  Copyright © 2015 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class HomeViewController: UITableViewController, UISearchResultsUpdating, ContactsViewControllerDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    var summaryResponses : [MMXChannelSummaryResponse] = []
    var filteredSummaryResponses : [MMXChannelSummaryResponse] = []
    var subscribedChannels : [MMXChannel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        if let revealVC = self.revealViewController() {
            self.navigationItem.leftBarButtonItem!.target = revealVC
            self.navigationItem.leftBarButtonItem!.action = "revealToggle:"
            self.view.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
        
        // Indicate that you are ready to receive messages now!
        MMX.start()
        // Handling disconnection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didDisconnect:", name: MMUserDidReceiveAuthenticationChallengeNotification, object: nil)

        
        // Add search bar
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let user = MMUser.currentUser() {
            self.title = "\(user.firstName ?? "") \(user.lastName ?? "")"
        }
        
        // Get all channels the current user is subscribed to
        MMXChannel.subscribedChannelsWithSuccess({ [weak self] channels in
            self?.subscribedChannels = channels
            // Get summaries
            let channelsSet = Set(channels)
            MMXChannel.channelSummary(channelsSet, numberOfMessages: 5, numberOfSubcribers: 5, success: {  summaryResponses in
                self?.summaryResponses = summaryResponses
                self?.tableView.reloadData()
            }, failure: { error in
                print(error)
            })
        }) { error in
            print(error)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = nil
    }
    
    deinit {
        // Indicate that you are not ready to receive messages now!
        MMX.stop()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Notification handler
    
    private func didDisconnect(notification: NSNotification) {
        // Indicate that you are not ready to receive messages now!
        MMX.stop()
        
        // Redirect to the login screen
        if let revealVC = self.revealViewController() {
            revealVC.rearViewController.navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    // MARK: - Helpers
    
    private func isOwnerForChat(name: String) -> MMXChannel? {
        if let channel = channelForName(name) where channel.ownerUserID == MMUser.currentUser()?.userID {
            return channel
        }

        return nil
    }
    
    private func channelForName(name: String) -> MMXChannel? {
        for channel in subscribedChannels {
            if channel.name == name {
                return channel
            }
        }
        
        return nil
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
        cell.summaryResponse = searchController.active ? filteredSummaryResponses[indexPath.row] : summaryResponses[indexPath.row]
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let summaryResponse = summaryResponses[indexPath.row]
        let isLastPersonInChat = (summaryResponse.messages.last as! MMXPubSubItemChannel).publisher.userId == MMUser.currentUser()?.userID
        
        if isLastPersonInChat {
            // Current user must be the owner of the channel to delete it
            if let chat = isOwnerForChat(summaryResponse.channelName) {
                let delete = UITableViewRowAction(style: .Normal, title: "Delete") { [weak self] action, index in
                    chat.deleteWithSuccess({ _ in
                        self?.summaryResponses.removeAtIndex(index.row)
                        tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Fade)
                    }, failure: { error in
                        print(error)
                    })
                }
                delete.backgroundColor = UIColor.redColor()
                return [delete]
            }
        }
        
        // Unsubscribe
        let leave = UITableViewRowAction(style: .Normal, title: "Leave") { [weak self] action, index in
            if let chat = self?.channelForName(summaryResponse.channelName) {
                chat.unSubscribeWithSuccess({ _ in
                    self?.summaryResponses.removeAtIndex(index.row)
                    tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Fade)
                }, failure: { error in
                    print(error)
                })
            }
        }
        leave.backgroundColor = UIColor.orangeColor()
        return [leave]
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
 
    }
    
    //MARK: - ContactsViewControllerDelegate
    
    func contactsControllerDidFinish(with selectedUsers: [MMUser]) {
        if let chatVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as? ChatViewController {
            chatVC.recipients = selectedUsers + [MMUser.currentUser()!]
            self.navigationController?.pushViewController(chatVC, animated: false)
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showChatFromChannelSummary" {
            if let chatVC = segue.destinationViewController as? ChatViewController, let cell = sender as? SummaryResponseCell {
                if let messages = cell.summaryResponse.messages as? [MMXPubSubItemChannel] {
                    chatVC.chat = channelForName(cell.summaryResponse.channelName)
                    chatVC.messages = messages.map({ PubSubItemChannelMessage(pubSubItemChannel: $0) })
                }
            }
        } else if segue.identifier == "showContactsSelector" {
            if let navigationVC = segue.destinationViewController as? UINavigationController {
                if let contactsVC = navigationVC.topViewController as? ContactsViewController {
                    contactsVC.delegate = self
                    contactsVC.title = "New message"
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredSummaryResponses = summaryResponses.filter { summary in
            if let pubSubItems = summary.messages as? [MMXPubSubItemChannel] {
                for message in pubSubItems {
                    let content = message.content as! [String : String]!
                    return content["message"]!.containsString(searchController.searchBar.text!.lowercaseString)
                }
            }
            
            return false
        }
        
        tableView.reloadData()
    }

}

