//
//  PubSubItemChannelMessage.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/14/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import MMX

class PubSubItemChannelMessage: NSObject, JSQMessageData {
    
    let underlyingMessage: MMXPubSubItemChannel
    
    lazy var type: MessageType = {
        return MessageType(rawValue: self.underlyingMessage.content["type"]! as! String)
    }()!
    
    lazy var mediaContent: JSQMessageMediaData! = {
        let messageContent = self.underlyingMessage.content
        
        switch self.type {
        case .Text:
            return nil
        case .Location:
            let locationMediaItem = JSQLocationMediaItem()
            locationMediaItem.appliesMediaViewMaskAsOutgoing = false
            return locationMediaItem
        case .Photo:
            let photoMediaItem = JSQPhotoMediaItem()
            photoMediaItem.appliesMediaViewMaskAsOutgoing = false
            photoMediaItem.image = nil
            return photoMediaItem
        case .Video:
            let videoMediaItem = JSQVideoMediaItem()
            videoMediaItem.appliesMediaViewMaskAsOutgoing = false
            videoMediaItem.fileURL = nil
            videoMediaItem.isReadyToPlay = false
            return videoMediaItem
        }
    }()
    
    init(pubSubItemChannel: MMXPubSubItemChannel) {
        self.underlyingMessage = pubSubItemChannel
    }
    
    func senderId() -> String! {
        return underlyingMessage.publisher.userId
    }

    func senderDisplayName() -> String! {
        if let displayName = underlyingMessage.publisherInfo.displayName {
            return displayName
        } else {
            if let summary = ChannelManager.sharedInstance.channelSummaryForChannelName(underlyingMessage.channelName) {
                if let subscribers = summary.subscribers as? [MMXUserInfo] {
                    for user in subscribers {
                        if underlyingMessage.publisher.userId == user.userId {
                            return user.displayName
                        }
                    }
                }
            }
        }
        
        return "Uknown sender"
    }

    func date() -> NSDate! {
        if let date = ChannelManager.sharedInstance.dateForLastPublishedTime(underlyingMessage.metaData.creationDate!) {
            return date
        }
        return NSDate()
    }

    func isMediaMessage() -> Bool {
        return (type != MessageType.Text)
    }

    func messageHash() -> UInt {
        return UInt(abs(underlyingMessage.itemId!.hash))
    }

    func text() -> String! {
        return underlyingMessage.content["message"]! as! String
    }

    func media() -> JSQMessageMediaData! {
        return mediaContent
    }
}
