//
//  ViewController.swift
//  MyProject28
//
//  Created by Георгий Евсеев on 20.12.22.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    @IBOutlet var secret: UITextView!
    var button: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Enter Password", style: .plain, target: self, action: #selector(makePassword))
        navigationItem.leftBarButtonItem?.isHidden = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(saveSecretMessage))
        navigationItem.rightBarButtonItem?.isHidden = true

        title = "Nothing to see here"

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return }

        let keyboardScreenEnd = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEnd, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        secret.scrollIndicatorInsets = secret.contentInset

        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }

    func unlockSecretMessage() {
        secret.isHidden = false
        title = "Secret stuff!"
        navigationItem.rightBarButtonItem?.isHidden = false
        navigationItem.leftBarButtonItem?.isHidden = false

        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
    }

    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }

        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
        navigationItem.rightBarButtonItem?.isHidden = true
        navigationItem.leftBarButtonItem?.isHidden = true
    }

    @IBAction func enterPassword(_ sender: Any) {
        let ac = UIAlertController(title: "Password", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let password = ac?.textFields?[0].text else { return }
            self?.submit(password)
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }

    func submit(_ password: String) {
        let lowerAnswer = password.lowercased()
        if lowerAnswer == KeychainWrapper.standard.string(forKey: "Password") {
            unlockSecretMessage()
        } else { return }
    }

    @objc func makePassword() {
        let ac = UIAlertController(title: "Enter Password", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak ac] _ in
            guard let password = ac?.textFields?[0].text else { return }
            KeychainWrapper.standard.set(password, forKey: "Password")
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
}
