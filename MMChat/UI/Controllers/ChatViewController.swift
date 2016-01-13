//
//  ChatViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/5/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    internal var chat : MMXChannel?
    var messages = [JSQMessageData]()
    var usersIDs : [String]!
    var avatars = Dictionary<String, UIImage>()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    var recipients : [MMUser]! {
        didSet {
            if recipients.count == 2 {
                var users = recipients
                if let currentUser = MMUser.currentUser(), index = users.indexOf(currentUser) {
                    users.removeAtIndex(index)
                }
                navigationItem.title = users.first?.firstName!
            } else {
                navigationItem.title = "Group"
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = MMUser.currentUser() else {
            return
        }
        
        senderId = user.userName
        senderDisplayName = user.firstName
        showLoadEarlierMessagesHeader = true
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        
        // Find channel by usersIDs or users
        if usersIDs != nil {
            MMUser.usersWithUserIDs(usersIDs, success: { [weak self] users in
                self?.recipients = users
                self?.findChannelsBySubscribers(users)
            }) { error in
                print("[ERROR]: \(error)")
            }
        } else if recipients != nil {
            self.findChannelsBySubscribers(recipients)
        }
    }
    
    private func findChannelsBySubscribers(users: [MMUser]) {
        //Check if channel exists
        MMXChannel.findChannelsBySubscribers(users, matchType: .EXACT_MATCH, success: { [weak self] channels in
            if channels.count == 0 {
                //Create new chat
                let subscribers = Set(users)
                // Do not create channels with same name
                let name = "\(self!.senderId)_\(Int(arc4random_uniform(UInt32.max) + 1))"
                MMXChannel.createWithName(name, summary: "\(self!.senderDisplayName) private chat", isPublic: false, publishPermissions: .Subscribers, subscribers: subscribers, success: { channel in
                    self?.chat = channel
                }, failure: { error in
                    print("[ERROR]: \(error)")
                })
            } else {
//                if let channelInfo = channels.first as? MMXChannelInfo {
//                    MMXChannel.channelForName(channelInfo.name, isPublic: false, success: { [weak self] channel in
//                        self?.chat = channel
//                    }, failure: { (error) -> Void in
//                        print("[ERROR]: \(error)")
//                    })
//                }
                
                //Use existing
                self?.chat = channels.first
            }
        }) { error in
            print("[ERROR]: \(error)")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveMessage:", name: MMXDidReceiveMessageNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Public methods
    
    func addSubscribers(newSubscribers: [MMUser]) {
        chat?.subscribersWithLimit(100, offset: 0, success: { (count, subscribedUsers) -> Void in
            //Check if channel exists
            let allSubscribers = Set(newSubscribers + subscribedUsers)
            MMXChannel.findChannelsBySubscribers(Array(allSubscribers), matchType: .EXACT_MATCH, success: { channels in
                if channels.count == 1 {
                    //FIXME: use channel
                } else if channels.count == 0 {
                    self.chat?.addSubscribers(newSubscribers, success: { invalidUsers in
                        print(invalidUsers)
                    }, failure: { error in
                        print("[ERROR]: \(error)")
                    })
                }
            }, failure: { error in
                print("[ERROR]: \(error)")
            })
        }, failure: { error in
            print("[ERROR]: \(error)")
        })
    }
    
    // MARK: - MMX methods
    
    func didReceiveMessage(notification: NSNotification) {
        
        //Show the typing indicator to be shown
        showTypingIndicator = !self.showTypingIndicator
        
        // Scroll to actually view the indicator
        scrollToBottomAnimated(true)
        
        /**
         *  Upon receiving a message, you should:
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        let tmp : [NSObject : AnyObject] = notification.userInfo!
        let mmxMessage = tmp[MMXMessageKey] as! MMXMessage
        
        // Allow typing indicator to show
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            let message = Message(message: mmxMessage)
            self.messages.append(message)
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            self.finishReceivingMessageAnimated(true)
            
            if message.isMediaMessage() {
                
                switch message.type {
                case .Text:
                    print("Text")
                case .Location:
                    let location = CLLocation(latitude: (mmxMessage.messageContent["latitude"]! as NSString).doubleValue, longitude: (mmxMessage.messageContent["longitude"]! as NSString).doubleValue)
                    let locationMediaItem = JSQLocationMediaItem()
                    locationMediaItem.setLocation(location) {
                        self.collectionView?.reloadData()
                    }
                    message.mediaContent = locationMediaItem
                case .Photo:
                    let attachment = mmxMessage.attachments?.first
                    attachment?.downloadFileWithSuccess({ (fileURL) -> Void in
                        let image = UIImage(contentsOfFile: fileURL.path!)
                        let photo = JSQPhotoMediaItem(image: image)
                        message.mediaContent = photo
                        self.collectionView?.reloadData()
                        print("Did load image")
                        }, failure: { (error) -> Void in
                            print(error)
                    })
                    
                case .Video:
                    let attachment = mmxMessage.attachments?.first
                    attachment?.downloadFileWithSuccess({ (fileURL) -> Void in
                        let video = JSQVideoMediaItem(fileURL: fileURL, isReadyToPlay: true)
                        message.mediaContent = video
                        self.collectionView?.reloadData()
                        }, failure: { (error) -> Void in
                            print(error)
                    })
                }
            }
        })
    }
    
    //MARK: - everriden JSQMessagesViewController methods
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        guard let channel = self.chat else { return }
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        let forcedString: String = text
        let messageContent = [
            "type": MessageType.Text.rawValue,
            "message": forcedString,
        ]

        let mmxMessage = MMXMessage(toChannel: channel, messageContent: messageContent)
        mmxMessage.sendWithSuccess( { (invalidUsers) -> Void in
            self.finishSendingMessageAnimated(true)
        }) { (error) -> Void in
            print(error)
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
        let alertController = UIAlertController(title: "Media messages", message: nil, preferredStyle: .Alert)
        
        let sendPhotoAction = UIAlertAction(title: "Send photo", style: .Default) { (_) in
            self.addPhotoMediaMessage()
        }
        let twoAction = UIAlertAction(title: "Send location", style: .Default) { (_) in
            self.addLocationMediaMessageCompletion()
        }
        let threeAction = UIAlertAction(title: "Send video", style: .Default) { (_) in
            self.addVideoMediaMessage()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addAction(sendPhotoAction)
        alertController.addAction(twoAction)
        alertController.addAction(threeAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {
        messages.removeAtIndex(indexPath.item)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item]
        if message.senderId() == senderId {
            return outgoingBubbleImageView
        }
        
        return incomingBubbleImageView
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date())
        }
        
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        /**
        *  iOS7-style sender name labels
        */
        if message.senderId() == senderId {
            return nil
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = messages[indexPath.item - 1]
            if previousMessage.senderId()  == message.senderId() {
                return nil
            }
        }
        
        /**
        *  Don't specify attributes to use the defaults.
        */
        return NSAttributedString(string: message.senderDisplayName())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return nil
    }
    
    // MARK: UICollectionView DataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if !message.isMediaMessage() {
            if message.senderId() == senderId {
                cell.textView!.textColor = UIColor.blackColor()
            } else {
                cell.textView!.textColor = UIColor.whiteColor()
            }
            
            // FIXME: 1
            cell.textView!.linkTextAttributes = [
                NSForegroundColorAttributeName : cell.textView?.textColor as! AnyObject,
                NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue | NSUnderlineStyle.PatternSolid.rawValue
            ]
        }
        
        return cell
    }
    
    // MARK: JSQMessagesCollectionViewDelegateFlowLayout methods
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        /**
        *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
        */
        
        /**
        *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
        *  The other label height delegate methods should follow similarly
        *  Show a timestamp for every 3rd message
        */
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        /**
         *  iOS7-style sender name labels
         */
        let currentMessage = messages[indexPath.item]
        if currentMessage.senderId() == senderId {
            return 0.0
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = messages[indexPath.item - 1]
            if previousMessage.senderId() == currentMessage.senderId() {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("Load earlier messages!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        print("Tapped avatar!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        print("Tapped message bubble!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        print("Tapped cell at \(touchLocation)")
    }
    
    // MARK: Helper methods
    
    private func addLocationMediaMessageCompletion() {
        let ferryBuildingInSF = CLLocation(latitude: 37.795313, longitude: -122.393757)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let messageContent = [
            "type": MessageType.Location.rawValue,
            "latitude": "\(ferryBuildingInSF.coordinate.latitude)",
            "longitude": "\(ferryBuildingInSF.coordinate.longitude)"
        ]
        let mmxMessage = MMXMessage(toChannel: self.chat!, messageContent: messageContent)
        mmxMessage.sendWithSuccess( { (invalidUsers) -> Void in
            self.finishSendingMessageAnimated(true)
        }) { (error) -> Void in
            print(error)
        }
    }
    
    private func addPhotoMediaMessage() {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let messageContent = [ "type": MessageType.Photo.rawValue ]
        let mmxMessage = MMXMessage(toChannel: self.chat!, messageContent: messageContent)
        let imageName = "goldengate"
        let imageType = "png"
        let imagePath = NSBundle.mainBundle().pathForResource(imageName, ofType: imageType)
        let urlPath = NSURL.init(fileURLWithPath: imagePath!)
        let attachment = MMAttachment.init(fileURL: urlPath, mimeType: "image/*", name: "Golden gate", description: "Image")
        mmxMessage.addAttachment(attachment)
        mmxMessage.sendWithSuccess({ (invalidUsers) -> Void in
            self.finishSendingMessageAnimated(true)
        }) { (error) -> Void in
            print(error)
        }
    }
    
    private func addVideoMediaMessage() {
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let messageContent = [
            "type": MessageType.Video.rawValue,
        ]
        
        let mmxMessage = MMXMessage(toChannel: self.chat!, messageContent: messageContent)
        let videoName = "small"
        let videoType = "mp4"
        let videoPath = NSBundle.mainBundle().pathForResource(videoName, ofType: videoType)
        let urlPath = NSURL(fileURLWithPath: videoPath!)
        let attachment = MMAttachment(fileURL: urlPath, mimeType: "video/*", name: "Lego", description: "small video")
        mmxMessage.addAttachment(attachment)
        mmxMessage.sendWithSuccess({ (invalidUsers) -> Void in
            self.finishSendingMessageAnimated(true)
        }) { (error) -> Void in
            print(error)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetailsSegue" {
            if let destinationVC = segue.destinationViewController as? DetailsViewController {
                destinationVC.recipients = recipients
            }
        }
    }

}
