//
//  ChangePasswordViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 1/4/16.
//  Copyright © 2016 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class ChangePasswordViewController: BaseViewController {

    @IBOutlet weak var txtfCurrentPassword : UITextField!
    @IBOutlet weak var txtfNewPassword : UITextField!
    @IBOutlet weak var txtfNewPasswordAgain : UITextField!
    
    @IBAction func cancelAction() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func submitAction() {
        
        guard let user = MMUser.currentUser(),
            let currentPassword = txtfCurrentPassword.text where (currentPassword.isEmpty == false),
            let newPassword = txtfNewPassword.text where (newPassword.isEmpty == false),
            let newPasswordAgain = txtfNewPasswordAgain.text where (newPasswordAgain.isEmpty == false && newPassword == newPasswordAgain)
            else {
                showAlert("Either you entered the incorrect current password or your new password does not match", title: "Passwords do not match", closeTitle: "Try again")
                return
        }
        
        let updateRequest = MMUpdateProfileRequest()
        updateRequest.firstName = user.firstName
        updateRequest.lastName = user.lastName
        updateRequest.email = user.email
        updateRequest.tags = user.tags
        updateRequest.extras = user.extras
        updateRequest.password = newPassword
        
        self.showLoadingIndicator()

        MMUser.updateProfile(updateRequest, success: { [weak self] user in
            self?.hideLoadingIndicator()
            self?.showAlert("Your password has been successfully changed", title: "Password Reset", closeTitle: "Continue", handler: { (_) -> Void in
                self?.cancelAction()
            })
        }) { [weak self] error in
            self?.hideLoadingIndicator()
            self?.showAlert("Either you entered the incorrect current password or your new password does not match", title: "Passwords do not match", closeTitle: "Try again")
        }
    }
}
