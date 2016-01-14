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
            if let subscribers = summaryResponse.subscribers as? [MMXUserInfo] {
                var subscribersTitle = ""
                for user in subscribers {
                    subscribersTitle += (subscribers.indexOf(user) == subscribers.count - 1) ? user.displayName! : "\(user.displayName!), "
                }
                lblSubscribers.text = subscribersTitle
            }
            if let messages = summaryResponse.messages as? [MMXPubSubItemChannel], content = messages.last?.content as! [String : String]! {
                lblMessage.text = content["message"]!
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
                return lastPublishedTime.timeIntervalSince1970 > lastViewTime.timeIntervalSince1970
            }
        }
        
        return false
    }
    
    private func displayLastPublishedTime() -> String! {
        let secondsInDay: NSTimeInterval = 24 * 60 * 60
        let lastDay = NSDate(timeInterval: secondsInDay, sinceDate: NSDate())
        
        if let lastPublishedTime = dateForLastPublishedTime() {
            let result = lastDay.compare(lastPublishedTime)
            if result == .OrderedAscending {
                return JSQMessagesTimestampFormatter.sharedFormatter().timeForDate(lastPublishedTime)
            } else {
                return JSQMessagesTimestampFormatter.sharedFormatter().relativeDateForDate(lastPublishedTime)
            }
        }
        
        return summaryResponse.lastPublishedTime!
    }
    
    private func dateForLastPublishedTime() -> NSDate? {
        let formatter = JSQMessagesTimestampFormatter.sharedFormatter().dateFormatter
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.dateFromString(summaryResponse.lastPublishedTime)
    }

}
