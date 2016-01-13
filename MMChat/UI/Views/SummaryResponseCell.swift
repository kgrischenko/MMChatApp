//
//  SummaryResponseCell.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/4/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

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
                    if subscribers.indexOf(user) == subscribers.count - 1 {
                        subscribersTitle += user.displayName!
                    } else {
                        subscribersTitle += "\(user.displayName!), "
                    }
                }
                lblSubscribers.text = subscribersTitle
            }
            if let messages = summaryResponse.messages as? [MMXPubSubItemChannel], content = messages.last?.content as! [String : String]! {
                lblMessage.text = content["message"]!
            }
            
            lblLastTime.text = summaryResponse.lastPublishedTime!
//            lblSubscribers.text = "John Smith, Jane Doe, Keanu Reaves"
//            lblMessage.text = "Copyright © 2016 Kostya Grishchenko. All rights reserved."
//            lblLastTime.text = "Wednesday"
            ivMessageIcon.image = (summaryResponse.subscribers.count > 2) ? UIImage(named: "messages.png") : UIImage(named: "message.png")
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        vNewMessageIndicator.layer.cornerRadius = vNewMessageIndicator.bounds.width / 2
        vNewMessageIndicator.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
