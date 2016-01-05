//
//  HomeViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 12/29/15.
//  Copyright © 2015 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class HomeViewController: UITableViewController {
    
    let searchController = UISearchController(searchResultsController: nil)
    var messages : [MMXMessage] = []
    var filteredMessages : [MMXMessage] = []
    var summaryResponses : [MMXChannelSummaryResponse] = []

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
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
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
    }
    
    // MARK: - Helpers
    
    func filterContentForSearchText(searchText: String) {
//        filteredCandies = candies.filter { candy in
//            return candy.name.lowercaseString.containsString(searchText.lowercaseString)
//        }
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredMessages.count
        }
        return messages.count
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


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

