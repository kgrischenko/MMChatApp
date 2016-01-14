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
        return underlyingMessage.publisherInfo.displayName
    }

    func date() -> NSDate! {
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
