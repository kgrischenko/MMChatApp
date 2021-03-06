//
//  Message.swift
//  MMChat
//
//  Created by Pritesh Shah on 9/9/15.
//  Copyright (c) 2015 Magnet Systems, Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MMX

class Message : NSObject, JSQMessageData {
    
    var mediaCompletionBlock: JSQLocationMediaItemCompletionBlock?
    let underlyingMessage: MMXMessage
    
    lazy var type: MessageType = {
        return MessageType(rawValue: self.underlyingMessage.messageContent["type"]!)
    }()!
    
    lazy var mediaContent: JSQMessageMediaData! = {
        
        switch self.type {
        case .Text:
            return nil
        case .Location:
            let messageContent = self.underlyingMessage.messageContent
            let locationMediaItem = JSQLocationMediaItem()
            locationMediaItem.appliesMediaViewMaskAsOutgoing = false

            if let latitude = Double(messageContent["latitude"]!), let longitude = Double(messageContent["longitude"]!) {
                let location = CLLocation(latitude: latitude, longitude: longitude)
                locationMediaItem.setLocation(location, withCompletionHandler: self.mediaCompletionBlock ?? nil)
            }

            self.mediaCompletionBlock = nil
            return locationMediaItem

        case .Photo:
            let photoMediaItem = JSQPhotoMediaItem()
            photoMediaItem.appliesMediaViewMaskAsOutgoing = false
            photoMediaItem.image = nil
            
            let attachment = self.underlyingMessage.attachments?.first
            attachment?.downloadFileWithSuccess({ [weak self] fileURL in
                photoMediaItem.image = UIImage(contentsOfFile: fileURL.path!)
                if self?.mediaCompletionBlock != nil {
                    self?.mediaCompletionBlock!()
                    self?.mediaCompletionBlock = nil
                }
            }, failure: nil)
            
            return photoMediaItem
            
        case .Video:
            let videoMediaItem = JSQVideoMediaItem()
            videoMediaItem.appliesMediaViewMaskAsOutgoing = false
            videoMediaItem.isReadyToPlay = true
            
            let attachment = self.underlyingMessage.attachments?.first
            videoMediaItem.fileURL = attachment!.downloadURL
            
            return videoMediaItem
        }
    }()
    
    init(message: MMXMessage) {
        self.underlyingMessage = message
    }
    
    func senderId() -> String! {
        return underlyingMessage.sender!.userID
    }
    
    func senderDisplayName() -> String! {
        return (underlyingMessage.sender!.firstName != nil) ? underlyingMessage.sender!.firstName : underlyingMessage.sender!.userName
    }
    
    func date() -> NSDate! {
        if let date = underlyingMessage.timestamp {
            return date
        }
        
        return NSDate()
    }
    
    func isMediaMessage() -> Bool {
        return (type != MessageType.Text)
    }
    
    func messageHash() -> UInt {
        return UInt(abs(underlyingMessage.messageID!.hash))
    }
    
    func text() -> String! {
        return underlyingMessage.messageContent[Constants.ContentKey.Message]! as String
    }
    
    func media() -> JSQMessageMediaData! {
        return mediaContent
    }
    
    override var description: String {
        return "senderId is \(senderId()), messageContent is \(underlyingMessage.messageContent)"
    }
    
}

enum MessageType: String, CustomStringConvertible {
    case Text = "text"
    case Location = "location"
    case Photo = "photo"
    case Video = "video"
    
    var description: String {
        
        switch self {
            
        case .Text:
            return "text"
        case .Location:
            return "location"
        case .Photo:
            return "photo"
        case .Video:
            return "video"
        }
    }
}
