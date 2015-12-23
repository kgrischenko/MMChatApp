//
//  SignInViewController.swift
//  MMChat
//
//  Created by Kostya Grishchenko on 12/23/15.
//  Copyright © 2015 Kostya Grishchenko. All rights reserved.
//

import UIKit

class SignInViewController : BaseViewController {
    
    @IBOutlet weak var txtfEmail : UITextField?
    @IBOutlet weak var txtfPassword : UITextField?
    @IBOutlet weak var btnRemember : UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func signInAction() {
    
    }
    
    @IBAction func createAccountAction() {
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
