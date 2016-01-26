//
//  VideoPlayerViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/26/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import DZVideoPlayerViewController
import MagnetMax

class VideoPlayerViewController: BaseViewController, DZVideoPlayerViewControllerDelegate {
    
    @IBOutlet weak var videoContainerView: DZVideoPlayerViewControllerContainerView!
    var videoPlayerViewController: DZVideoPlayerViewController!
    var attachment: MMAttachment!
    var fileURL: NSURL!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Show player
        self.videoPlayerViewController = self.videoContainerView.videoPlayerViewController
        self.videoPlayerViewController.delegate = self
        self.videoPlayerViewController.configuration.isShowFullscreenExpandAndShrinkButtonsEnabled = false
        self.videoPlayerViewController.activityIndicatorView?.startAnimating()
        
        // Download file
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let documentsUrl = NSURL(fileURLWithPath: documentsPath, isDirectory: true)
        fileURL = documentsUrl.URLByAppendingPathComponent(attachment!.name!)
        print(fileURL!)
        
        attachment.downloadToFile(fileURL, success: { [weak self] () in
            self?.startPlay()
        }) { [weak self] error in
            print(error)
            self?.videoPlayerViewController.activityIndicatorView?.stopAnimating()
            self?.playerFailedToLoadAssetWithError(error)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if NSFileManager.defaultManager().fileExistsAtPath(fileURL!.path!) {
            try! NSFileManager.defaultManager().removeItemAtURL(fileURL!)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    func startPlay() {

        //    self.videoPlayerViewController.configuration.isBackgroundPlaybackEnabled = NO;
        //    self.videoPlayerViewController.configuration.isHideControlsOnIdleEnabled = NO;
        
        self.videoPlayerViewController.activityIndicatorView?.stopAnimating()
        self.videoPlayerViewController.videoURL = fileURL
        self.videoPlayerViewController.prepareAndPlayAutomatically(true)
    }
    
    //MARK: - DZVideoPlayerViewControllerDelegate
    
    func playerDoneButtonTouched() {
        self.videoContainerView.videoPlayerViewController.stop()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func playerFailedToLoadAssetWithError(error: NSError!) {
        showAlert(error.localizedDescription, title: "Error", closeTitle: "Close") { [weak self] _ in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
}
