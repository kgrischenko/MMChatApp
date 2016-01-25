//
//  ChannelManager.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/19/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class ChannelManager: NSObject {
    
    static let sharedInstance = ChannelManager()
    
    var channels : [MMXChannel]?
    var channelSummaries : [MMXChannelSummaryResponse]?
    
    func channelForName(name: String) -> MMXChannel? {
        
        if nil == channels { return nil }
        
        for channel in channels! {
            if channel.name == name {
                return channel
            }
        }
        
        return nil
    }
    
    func channelSummaryForChannelName(name: String) -> MMXChannelSummaryResponse? {
        
        if nil == channels || nil == channelSummaries { return nil }
        
        if let channel = channelForName(name) {
            for summary in channelSummaries! {
                if summary.channelName == channel.name {
                    return summary
                }
            }
        }
        
        return nil
    }
    
    func isOwnerForChat(name: String) -> MMXChannel? {
        if let channel = channelForName(name) where channel.ownerUserID == MMUser.currentUser()?.userID {
            return channel
        }
        
        return nil
    }
    
    func dateForLastPublishedTime(stringTime: String) -> NSDate? {
        var date = stringTime
        if date.containsString(".") {
            date = date.substringToIndex(date.characters.indexOf(".")!)
        }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.dateFromString(date)
    }
    
    func newChannelName() -> String {
        // Example: 20120718073109
        //    year: 20120000000000
        //   month: 00000700000000
        //     day: 00000018000000
        //    hour: 00000000070000
        //  minute: 00000000003100
        //  second: 00000000000009
        
        let components = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: NSDate())
        var fakeTimestamp: Int64 = 0
        let tenMillions : Int64 = 10000000000
        fakeTimestamp += Int64(components.year) * tenMillions
        fakeTimestamp += components.month * 100000000
        fakeTimestamp += components.day * 1000000
        fakeTimestamp += components.hour * 10000
        fakeTimestamp += components.minute * 100
        fakeTimestamp += components.second
        
        return "\(fakeTimestamp)"
    }
    
    func relativeDateForDate(date: NSDate) -> String {
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter.stringFromDate(date)
    }
    
    // MARK: - Private implementation
    
    private override init() {
        super.init()
        formatter.locale = NSLocale.currentLocale()
        formatter.timeZone = NSTimeZone(name: "GMT")
    }
    
    private let formatter = NSDateFormatter()

}
