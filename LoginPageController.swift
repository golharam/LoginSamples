//
//  LoginPageController.swift
//
//
//  Created by Pavlo Dumyak on 1/9/17.
//  Copyright © 2017 Inoxoft Inc. All rights reserved.
//

import UIKit

class LoginPageController: BaseController,UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginPlaceholderView: UIView!
    @IBOutlet weak var showPasswordButton: UIButton!
    
    var loginCompletion: (()->())? = nil
    var hideKeyboardGesture: UITapGestureRecognizer!
    var textFieldArray:[UITextField] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addKeyboardHandling()
        setupLanguage()
        setupTextFields()
        loginButton.alpha = 0.5
        loginButton.isEnabled = false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func login() {
        LoginService.shared.login(name: emailTextField.text ?? "", password: passwordTextField.text ?? "", completion: { (value, error) in
            if value != nil && error == nil {
                print("Login success")
                self.loginCompletion?()
            } else {
                print("Login failed: Open login page")
                let alert = Alerts.getAlertControllerWith(title: "Login failed", description: "Login failed", confirmButton: nil)
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func loginDidTap(_ sender: Any) {
        if !CommonService.connectedToNetwork() {
            let alert = Alerts.getAlertControllerWith(title: "Error", description: "Internet connection is missing", confirmButton: nil)
            present(alert, animated: true, completion: nil)
            return
        }
        login()
    }
    
    @IBAction func showPassword(_ sender: Any) {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        if passwordTextField.isSecureTextEntry  {
            showPasswordButton.setImage(UIImage(named:"eye"), for: .normal)
        } else {
            showPasswordButton.setImage(UIImage(named:"eyeEnabled"), for: .normal)
        }
    }
}

extension LoginPageController {
    override func setupLanguage() {
    
    }
}

extension LoginPageController {
    
    func setupTextFields() {
        loginPlaceholderView.layer.cornerRadius = 5
        loginButton.layer.cornerRadius = 5
        textFieldArray = [self.emailTextField, self.passwordTextField]
        emailTextField.text = LoginService.shared.userInfo?[UserInfoKeys.email.rawValue] as? String ?? ""
        passwordTextField.text = ""
        emailTextField.delegate = self
        passwordTextField.delegate = self
        hideKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(LoginPageController.hideKeyboard))
        view.addGestureRecognizer(hideKeyboardGesture)
    }
    
    func hideKeyboard() {
        self.view.endEditing(false)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.autocorrectionType = .no
        if textField != textFieldArray.last {
            textField.returnKeyType = .next
        } else {
            textField.returnKeyType = .done
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.returnKeyType = .done
            passwordTextField.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let characterSet = NSMutableCharacterSet()
        characterSet.formUnion(with: NSCharacterSet.alphanumerics)
        characterSet.addCharacters(in: ".@_!#$%&'*+-/=?^_`{|}~")
        if string.rangeOfCharacter(from: characterSet.inverted) != nil {
            return false
        }
        
        if textField == passwordTextField && string != "" {
            if ((textField.text?.characters.count)!  > 20) {
                return false
            }
        }
    
        if emailTextField.text == "" || passwordTextField.text == "" {
            loginButton.alpha = 0.5
            loginButton.isEnabled = false
        } else {
            loginButton.alpha = 1
            loginButton.isEnabled = true
        }
        return true
    }
}

extension LoginPageController {
    
    func addKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                loginButtonBottomConstraint.constant = 20.0
            } else {
                loginButtonBottomConstraint.constant = endFrame?.size.height  ?? 20.0
            }
            UIView.animate(withDuration: 1, animations: { 
                self.view.layoutIfNeeded()
            })
        }
    }
}

