//
//  SummaryResponseCell.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/4/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax
import JSQMessagesViewController

class SummaryResponseCell: UITableViewCell {
    
    @IBOutlet weak var vNewMessageIndicator : UIView!
    @IBOutlet weak var lblSubscribers : UILabel!
    @IBOutlet weak var lblLastTime : UILabel!
    @IBOutlet weak var lblMessage : UILabel!
    @IBOutlet weak var ivMessageIcon : UIImageView!
    
    var summaryResponse : MMXChannelSummaryResponse! {
        didSet {
            if var subscribers = summaryResponse.subscribers as? [MMXUserInfo] {
                var subscribersTitle = ""
                var index: Int?
                subscribers.forEach({ user in
                    if user.userId == MMUser.currentUser()?.userID {
                        index = subscribers.indexOf(user)!
                    }
                })
                // Exclude currentUser
                if let _ = index { subscribers.removeAtIndex(index!) }
                
                for user in subscribers {
                    subscribersTitle += (subscribers.indexOf(user) == subscribers.count - 1) ? user.displayName! : "\(user.displayName!), "
                }
                lblSubscribers.text = subscribersTitle
            }
            if let messages = summaryResponse.messages as? [MMXPubSubItemChannel], content = messages.last?.content as! [String : String]! {
                lblMessage.text = content["message"] ?? "Attachment file"
            }
            
            lblLastTime.text = displayLastPublishedTime()
            ivMessageIcon.image = (summaryResponse.subscribers.count > 2) ? UIImage(named: "messages.png") : UIImage(named: "message.png")
            vNewMessageIndicator.hidden = !hasNewMessagesFromLastTime()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        vNewMessageIndicator.layer.cornerRadius = vNewMessageIndicator.bounds.width / 2
        vNewMessageIndicator.clipsToBounds = true
    }

    // MARK: - Helpers
    
    private func hasNewMessagesFromLastTime() -> Bool {
        if let lastViewTime = NSUserDefaults.standardUserDefaults().objectForKey(summaryResponse.channelName) as? NSDate {
            if let lastPublishedTime = dateForLastPublishedTime() {
                let result = lastViewTime.compare(lastPublishedTime)
                if result == .OrderedAscending {
                    return true
                } else {
                    return false
                }
            }
        } else if summaryResponse.messages.count > 0 {
            return true
        }
        
        return false
    }
    
    private func displayLastPublishedTime() -> String! {
        let secondsInDay: NSTimeInterval = 24 * 60 * 60
        let yesturday = NSDate(timeInterval: -secondsInDay, sinceDate: NSDate())
        
        if let lastPublishedTime = dateForLastPublishedTime() {
            let result = yesturday.compare(lastPublishedTime)
            if result == .OrderedAscending {
                return JSQMessagesTimestampFormatter.sharedFormatter().timeForDate(lastPublishedTime)
            } else {
                return ChannelManager.sharedInstance.relativeDateForDate(lastPublishedTime)
            }
        }
        
        return summaryResponse.lastPublishedTime!
    }
    
    private func dateForLastPublishedTime() -> NSDate? {
        return ChannelManager.sharedInstance.dateForLastPublishedTime(summaryResponse.lastPublishedTime!)
    }

}
