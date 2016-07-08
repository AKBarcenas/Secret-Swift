//
//  ViewController.swift
//  Secret Swift
//
//  Created by Alex on 7/8/16.
//  Copyright © 2016 Alex Barcenas. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    // View to display the secret text.
    @IBOutlet weak var secret: UITextView!
    // Authentication button for the secret text.
    @IBOutlet weak var authentication: UIButton!

    /*
     * Function Name: viewDidLoad
     * Parameters: None
     * Purpose: This method creates observers for some of the things that will occur while the app is running
     *   and sets the initial title for the app.
     * Return Value: None
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIKeyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        title = "Nothing to see here"
        
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplicationWillResignActiveNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     * Function Name: adjustForKeyboard
     * Parameters: notification - the notification linked with calling this method.
     * Purpose: This method adjusts the text view when the device's keyboard state changes.
     * Return Value: None
     */
    
    func adjustForKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
        
        if notification.name == UIKeyboardWillHideNotification {
            secret.contentInset = UIEdgeInsetsZero
        }
        
        else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    /*
     * Function Name: unlockSecretMessage
     * Parameters: None
     * Purpose: This method displays a secret message from the keychain in the text view and changes the title.
     * Return Value: None
     */
    
    func unlockSecretMessage() {
        secret.hidden = false
        authentication.hidden = true
        title = "Secret stuff!"
        
        if let text = KeychainWrapper.stringForKey("SecretMessage") {
            secret.text = text
        }
    }
    
    /*
     * Function Name: saveSecretMessage
     * Parameters: None
     * Purpose: This method saves a new secret message to the keychain and hides the text view.
     * Return Value: None
     */
    
    func saveSecretMessage() {
        if !secret.hidden {
            KeychainWrapper.setString(secret.text, forKey: "SecretMessage")
            secret.resignFirstResponder()
            secret.hidden = true
            authentication.hidden = false
            title = "Nothing to see here"
        }
    }
    
    /*
     * Function Name: authenticateUser
     * Parameters: sender - the button pressed to call this method.
     * Purpose: This method confirms that TouchID is usable on the device and asks the user to use it to
     *   authenticate themselves. Any errors that occur are displayed to the user in an alert view controller.
     * Return Value: None
     */
    
    @IBAction func authenticateUser(sender: AnyObject) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] (success: Bool, authenticationError: NSError?) -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    if success {
                        self.unlockSecretMessage()
                    }
                    
                    else {
                        if let error = authenticationError {
                            if error.code == LAError.UserFallback.rawValue {
                                let ac = UIAlertController(title: "Passcode? Ha!", message: "It's Touch ID or nothing – sorry!", preferredStyle: .Alert)
                                ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                                self.presentViewController(ac, animated: true, completion: nil)
                                return
                            }
                        }
                        
                        let ac = UIAlertController(title: "Authentication failed", message: "Your fingerprint could not be verified; please try again.", preferredStyle: .Alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(ac, animated: true, completion: nil)
                    }
                }
            }
        }
        
        else {
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(ac, animated: true, completion: nil)
        }
    }

}

