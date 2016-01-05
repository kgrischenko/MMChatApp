//
//  RegisterViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 12/23/15.
//  Copyright © 2015 Kostya Grishchenko. All rights reserved.
//

import UIKit
import MagnetMax

class RegisterViewController : BaseViewController {
    
    @IBOutlet weak var txtfFirstName : UITextField!
    @IBOutlet weak var txtfLastName : UITextField!
    @IBOutlet weak var txtfEmail : UITextField!
    @IBOutlet weak var txtfPassword : UITextField!
    @IBOutlet weak var txtfPasswordAgain : UITextField!
    @IBOutlet weak var btnReturn : UIButton!

    
    var viewOffset: CGFloat!
    var keyboardIsShowing = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: Handlers
    
    @IBAction func registerAction() {
        do {
            // Validate
            let (firstName, lastName, email, password) = try validateCredential()
            
            // Register
            let user = MMUser()
            user.userName = email
            user.firstName = firstName
            user.lastName = lastName
            user.password = password
            user.email = email
            
            user.register({ [weak self] user in
                self?.login()
            }, failure: { [weak self] error in
                if error.code == 409 {
                    // The user already exists, let's attempt a login
                    self?.login()
                }
                print("[ERROR]: \(error)")
            })
        } catch InputError.InvalidUserNames {
            self.showAlert("Please enter your first and last name", title: "Field required", closeTitle: "Close")
        } catch InputError.InvalidEmail {
            self.showAlert("Please enter your email", title: "Field required", closeTitle: "Close")
        } catch InputError.InvalidPassword {
            self.showAlert("Please enter your password and verify your password again", title: "Passwords do not match", closeTitle: "Close")
        } catch { }
    }
    
    @IBAction func returnToSignInAction() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    func keyboardWillShow(notification: NSNotification) {
        if false == keyboardIsShowing {
            if let userInfo = notification.userInfo {
                if let keyboardRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                    
                    let keyboardY = self.view.frame.height - keyboardRect.height
                    let buttonMaxY = self.btnReturn?.frame.maxY
                    if keyboardY <  buttonMaxY {
                        viewOffset = buttonMaxY! - keyboardY
                        self.moveView(true)
                    }
                }
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if true == keyboardIsShowing {
            self.moveView(false)
        }
    }
    
    // MARK: Private implementation
    
    private enum InputError: ErrorType {
        case InvalidUserNames
        case InvalidEmail
        case InvalidPassword
    }
    
    private func validateCredential() throws -> (String, String, String, String) {
        // Get values from UI
        guard let firstName = txtfFirstName.text where (firstName.isEmpty == false),
              let lastName = txtfLastName.text where (lastName.isEmpty == false) else {
            throw InputError.InvalidUserNames
        }
        
        guard let email = txtfEmail.text where (email.isEmpty == false) else {
            throw InputError.InvalidEmail
        }
        
        guard let password = txtfPassword.text where (password.isEmpty == false),
              let passwordAgain = txtfPasswordAgain.text where (passwordAgain.isEmpty == false && password == passwordAgain) else {
            throw InputError.InvalidPassword
        }
        
        return (firstName, lastName, email, password)
    }
    
    //MARK: Helpers
    
    func login() {
        do {
            // Validate
            let (_, _, email, password) = try validateCredential()
            
            // Login
            let credential = NSURLCredential(user: email, password: password, persistence: .None)
            
            MMUser.login(credential, success: {
                // Initialize Magnet Message
                MagnetMax.initModule(MMX.sharedInstance(), success: { [weak self] in
                    self?.performSegueWithIdentifier("registerToMenuSegue", sender: nil)
                }, failure: { error in
                        print("[ERROR]: \(error)")
                })
            }, failure: { error in
                print("[ERROR]: \(error.localizedDescription)")
            })
        } catch { }
    }
    
    func moveView(up: Bool) {
        let movement = (up ? -viewOffset : viewOffset)
        keyboardIsShowing = up
        
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame = CGRectOffset(self.view.frame, 0, movement)
        })
    }
    
    //MARK: UITextField delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }

}
