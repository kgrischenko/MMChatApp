//
//  DateFormatter.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/26/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

class DateFormatter: NSObject {
    
    let formatter: NSDateFormatter
    
    override init() {
        formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.timeZone = NSTimeZone(name: "GMT")
    }
    
    func relativeDateForDate(date: NSDate) -> String {
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter.stringFromDate(date)
    }
    
    func timeForDate(date: NSDate) -> String {
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        return formatter.stringFromDate(date)
    }
    
    func dateForStringTime(stringTime: String) -> NSDate? {
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
    
    func displayTime(stringTime: String) -> String! {
        let secondsInDay: NSTimeInterval = 24 * 60 * 60
        let yesturday = NSDate(timeInterval: -secondsInDay, sinceDate: NSDate())
        
        if let lastPublishedTime = dateForStringTime(stringTime) {
            let result = yesturday.compare(lastPublishedTime)
            if result == .OrderedAscending {
                return timeForDate(lastPublishedTime)
            } else {
                return relativeDateForDate(lastPublishedTime)
            }
        }
        
        return stringTime
    }

}
