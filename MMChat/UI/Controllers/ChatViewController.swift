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
import MobileCoreServices

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessageData]()
    var avatars = Dictionary<String, UIImage>()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    
    var chat : MMXChannel? {
        didSet {
            loadMessages()
        }
    }
    
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
        
        senderId = user.userID
        senderDisplayName = user.firstName
//        showLoadEarlierMessagesHeader = true
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        
        // Find recipients
        if chat != nil {
            chat?.subscribersWithLimit(100, offset: 0, success: { [weak self] (count, users) -> Void in
                self?.recipients = users
            }, failure: { (error) -> Void in
                print("[ERROR]: \(error)")
            })
            loadMessages()
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
                
                // Set channel name
                let name = "\(self!.senderDisplayName)_\(ChannelManager.sharedInstance.newChannelName())"
                
                MMXChannel.createWithName(name, summary: "\(self!.senderDisplayName) private chat", isPublic: false, publishPermissions: .Subscribers, subscribers: subscribers, success: { channel in
                    self?.chat = channel
                }, failure: { error in
                    print("[ERROR]: \(error)")
                    let alert = Popup(message: error.localizedDescription, title: error.localizedFailureReason ?? "", closeTitle: "Close", handler: { _ in
                        self?.navigationController?.popViewControllerAnimated(true)
                    })
                    alert.presentForController(self!)
                })
            } else if channels.count == 1 {
                //FIXME: temp solution
                let info : AnyObject = channels
                if let channelInfo = info as? [MMXChannelInfo] {
                    self?.chat = ChannelManager.sharedInstance.channelForName(channelInfo.first!.name)
                }
                
                //Use existing
//                self?.chat = channels.first
            }
        }) { error in
            print("[ERROR]: \(error)")
            let alert = Popup(message: error.localizedDescription, title: error.localizedFailureReason ?? "", closeTitle: "Close", handler: { _ in
                self.navigationController?.popViewControllerAnimated(true)
            })
            alert.presentForController(self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveMessage:", name: MMXDidReceiveMessageNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        // Save last channel view time
        if let _ = chat {
            NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: chat!.name)
        }
    }
    
    // MARK: - Public methods
    
    func addSubscribers(newSubscribers: [MMUser]) {
        
        guard let _ = recipients, let _ = chat else {
            print("Add subscribers error")
            return
        }
        
        let allSubscribers = Array(Set(newSubscribers + self.recipients))
        
        //Check if channel exists
        MMXChannel.findChannelsBySubscribers(allSubscribers, matchType: .EXACT_MATCH, success: { [weak self] channels in
            if channels.count == 1 {
                //FIXME: temporary solution
                let channelInfos : AnyObject = channels
                if let channelInfo = channelInfos as? [MMXChannelInfo] {
                    // Use existing channel
                    self?.chat = ChannelManager.sharedInstance.channelForName(channelInfo.first!.name)
                    self?.recipients = allSubscribers
                }
            } else if channels.count == 0 {
                self?.chat?.addSubscribers(newSubscribers, success: { invalidUsers in
                    self?.recipients = allSubscribers
                    print(invalidUsers)
                }, failure: { error in
                    print("[ERROR]: can't add subscribers - \(error)")
                })
            }
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
        
        let tmp : [NSObject : AnyObject] = notification.userInfo!
        let mmxMessage = tmp[MMXMessageKey] as! MMXMessage
        
        // Allow typing indicator to show
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            let message = Message(message: mmxMessage)
            self.messages.append(message)
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            self.finishReceivingMessageAnimated(true)
            
            if message.isMediaMessage() {
                message.mediaCompletionBlock = { [weak self] in self?.collectionView?.reloadData() }
            }
        })
    }
    
    //MARK: - overriden JSQMessagesViewController methods
    
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
        
        guard let _ = self.chat else { return }
        
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
        
        if message.senderId() == senderId {
            return nil
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = messages[indexPath.item - 1]
            if previousMessage.senderId() == message.senderId() {
                return nil
            }
        }
        
        // Don't specify attributes to use the defaults.
        
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
            
            cell.textView!.linkTextAttributes = [
                NSForegroundColorAttributeName : cell.textView?.textColor as! AnyObject,
                NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue | NSUnderlineStyle.PatternSolid.rawValue
            ]
        } else {
            
        }
        
        return cell
    }
    
    // MARK: JSQMessagesCollectionViewDelegateFlowLayout methods
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        //Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
        
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
        
        LocationManager.sharedInstance.getLocation { [weak self] location in
            JSQSystemSoundPlayer.jsq_playMessageSentSound()

            let messageContent = [
                "type": MessageType.Location.rawValue,
                "latitude": "\(location.coordinate.latitude)",
                "longitude": "\(location.coordinate.longitude)"
            ]
            let mmxMessage = MMXMessage(toChannel: (self?.chat)!, messageContent: messageContent)
            mmxMessage.sendWithSuccess( { (invalidUsers) -> Void in
                self?.finishSendingMessageAnimated(true)
            }) { (error) -> Void in
                print(error)
            }
        }
    }
    
    private func addPhotoMediaMessage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func addVideoMediaMessage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetailsSegue" {
            if let detailVC = segue.destinationViewController as? DetailsViewController {
                detailVC.recipients = recipients
                detailVC.channel = chat
            }
        }
    }
    
    private func loadMessages() {
        
        guard let channel = self.chat else { return }
        
        let dateComponents = NSDateComponents()
        dateComponents.day = -1
        
        let theCalendar = NSCalendar.currentCalendar()
        let now = NSDate()
        let dayAgo = theCalendar.dateByAddingComponents(dateComponents, toDate: now, options: NSCalendarOptions(rawValue: 0))
        
        channel.messagesBetweenStartDate(dayAgo, endDate: now, limit: 100, offset: 0, ascending: true, success: { totalCount, messages in
            self.messages = messages.map({ Message(message: $0) })
            self.collectionView?.reloadData()
            self.scrollToBottomAnimated(false)
        }, failure: { error in
            print(error)
        })
    }

}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        JSQSystemSoundPlayer.jsq_playMessageSentSound()

        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let messageContent = ["type" : MessageType.Photo.rawValue]
            let mmxMessage = MMXMessage(toChannel: chat!, messageContent: messageContent)
            if let data = UIImagePNGRepresentation(pickedImage) {
            
                let attachment = MMAttachment(data: data, mimeType: "image/*")
                mmxMessage.addAttachment(attachment)
                mmxMessage.sendWithSuccess({ (invalidUsers) -> Void in
                    self.finishSendingMessageAnimated(true)
                }) { (error) -> Void in
                    print(error)
                }
            }
        } else if let urlOfVideo = info[UIImagePickerControllerMediaURL] as? NSURL {
            let messageContent = ["type" : MessageType.Video.rawValue]
            let mmxMessage = MMXMessage(toChannel: chat!, messageContent: messageContent)
            let attachment = MMAttachment(fileURL: urlOfVideo, mimeType: "video/*")
            mmxMessage.addAttachment(attachment)
            mmxMessage.sendWithSuccess({ (invalidUsers) -> Void in
                self.finishSendingMessageAnimated(true)
            }) { (error) -> Void in
                print(error)
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
