//
//  VideoViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/22/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import Player
import MagnetMax

class VideoViewController: UIViewController, PlayerDelegate {
    
    var videoUrl: NSURL?
    var attachment: MMAttachment?
    private var player: Player!
    private let closeButton = UIButton(type: .Custom)
    
    // MARK: object lifecycle
    
    convenience init() {
        self.init(nibName: nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    // MARK: view lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.autoresizingMask = ([UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight])
        
        guard let attachment = self.attachment where attachment.name != nil else { return }
        
//        attachment.downloadFileWithSuccess({ [weak self] fileURL in
//            self?.showPlayerForURL(fileURL)
//        }) { error in
//            let alert = Popup(message: "Download video error", title: "", closeTitle: "Close", handler: { [weak self] _ in
//                self?.stopAndClose()
//            })
//            alert.presentForController(self)
//        }
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let fileUrl = NSURL(fileURLWithPath: documentsPath, isDirectory: true)
        videoUrl = fileUrl.URLByAppendingPathComponent(attachment.name!)
        print(videoUrl!)

        attachment.downloadToFile(videoUrl!, success: { [weak self] () in
            self?.showPlayerForURL(fileUrl)
        }) { (error) -> Void in
            print(error)
        }
        
        //Add close button
        closeButton.setTitle("Close", forState: .Normal)
        closeButton.addTarget(self, action: "stopAndClose", forControlEvents: .TouchUpInside)
        closeButton.titleLabel?.font = closeButton.titleLabel?.font.fontWithSize(19.0)
        closeButton.sizeToFit()
        self.view.addSubview(closeButton)
        
        let toTop = NSLayoutConstraint(item: closeButton, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 8)
        let toLeft = NSLayoutConstraint(item: closeButton, attribute: .LeadingMargin, relatedBy: .Equal, toItem: self.view, attribute: .LeadingMargin, multiplier: 1, constant: 8)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints([toTop, toLeft])
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
            if NSFileManager.defaultManager().fileExistsAtPath(videoUrl!.path!) {
                try! NSFileManager.defaultManager().removeItemAtURL(videoUrl!)
            }
    }
    
    func showPlayerForURL(url: NSURL) {
        self.player = Player()
        self.player.delegate = self
        self.player.view.frame = self.view.bounds
        
        self.addChildViewController(self.player)
        self.view.addSubview(self.player.view)
        self.player.didMoveToParentViewController(self)
        
        self.player.setUrl(videoUrl!)
        self.player.playFromBeginning()

        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGestureRecognizer:")
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "stopAndClose")
        swipeGestureRecognizer.direction = [.Down, .Up]
        self.player.view.addGestureRecognizer(swipeGestureRecognizer)
        
        self.view.bringSubviewToFront(closeButton)
    }

    // MARK: UIGestureRecognizer
    
    func handleTapGestureRecognizer(gestureRecognizer: UITapGestureRecognizer) {
        switch (self.player.playbackState.rawValue) {
        case PlaybackState.Stopped.rawValue:
            self.player.playFromBeginning()
        case PlaybackState.Paused.rawValue:
            self.player.playFromCurrentTime()
        case PlaybackState.Playing.rawValue:
            self.player.pause()
        case PlaybackState.Failed.rawValue:
            self.player.pause()
        default:
            self.player.pause()
        }
    }
    
    func stopAndClose() {
        if player != nil {
            player.stop()
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: PlayerDelegate
    
    func playerReady(player: Player) {}
    
    func playerPlaybackStateDidChange(player: Player) {
        if player.playbackState == PlaybackState.Failed {
            let alert = Popup(message: "Unable play video", title: "", closeTitle: "Close", handler: { [weak self] _ in
                self?.stopAndClose()
            })
            alert.presentForController(self)
        } else if player.playbackState == PlaybackState.Paused {
            self.playerPlaybackDidEnd(player)
        }
    }
    
    func playerBufferingStateDidChange(player: Player) {
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
        closeButton.alpha = 1.0
        closeButton.hidden = false
        
        UIView.animateWithDuration(0.3, animations: {
            self.closeButton.alpha = 0.0
        }) { _ in
            self.closeButton.hidden = true
        }
    }
    
    func playerPlaybackDidEnd(player: Player) {
        
        closeButton.hidden = false
        
        UIView.animateWithDuration(0.1, animations: {
            self.closeButton.alpha = 1.0
        }, completion: nil)
    }

}
