//
//  BaseViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 12/23/15.
//  Copyright © 2015 Kostya Grishchenko. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        
        setConstrainsForActivityIndicator()
    }
    
    func setConstrainsForActivityIndicator() {
        let horizontalCenter = NSLayoutConstraint(item: activityIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
        let verticalCenter = NSLayoutConstraint(item: activityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1, constant: 0)
        self.view.addConstraints([horizontalCenter, verticalCenter])
    }
    
    func showAlert(message :String, title :String, closeTitle :String, handler:((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let closeAction = UIAlertAction(title: closeTitle, style: .Cancel, handler: handler)
        alert.addAction(closeAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
        self.view.userInteractionEnabled = false
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        self.view.userInteractionEnabled = true
    }

}
