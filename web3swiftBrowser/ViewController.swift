//
//  ViewController.swift
//  web3swiftBrowser
//
//  Created by Alexander Vlasov on 07.01.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import web3swift
import WKBridge
import AwaitKit

enum JSRequestsError: String {
    case noParamaters = "No parameters provided"
    case notEnoughParameters = "Not enough parameters provided"
    case accountOrDataIsInvalid = "Account or data is invalid"
    case dataIsInvalid = "Data is invalid"
    case genericError = "Some error occured"
}

class BrowserViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Settings Constants:
    let askConfirmationForSigning = true

    enum Method: String {
        case getAccounts
        case signTransaction
        case signMessage
        case signPersonalMessage
        case publishTransaction
        case approveTransaction
    }
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var reloadCancelItem: UIBarButtonItem!
    
    @IBAction func openSettings(_ sender: Any) {
    }
    
    @IBAction func reloadOrCancelChanges(_ sender: Any) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationController?.isNavigationBarHidden = true
//        navigationController?.hidesBarsOnTap = true
//        navigationController?.hidesBarsWhenVerticallyCompact = true
    }
    
    lazy var webView: WKWebView = {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = NSDate(timeIntervalSince1970: 0)
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
        let webView = WKWebView(
            frame: .zero,
            configuration: self.config
        )
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        return webView
    }()
    
    lazy var config: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        
        var js = ""
        
        if let filepath = Bundle.main.path(forResource: "Web3Swift", ofType: "js") {
            do {
                js += try String(contentsOfFile: filepath)
                NSLog("Loaded web3swift.js")
            } catch {
                NSLog("Failed to load web.js")
            }
        } else {
            NSLog("web3.js not found in bundle")
        }
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        return config
    }()
    
    @IBAction func unwindFromModal(segue:UIStoryboardSegue) { }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        
        webView.load(URLRequest(url: URL(string: "https://ownanumber.github.io/")!))
        searchTextField.text = "https://ownanumber.github.io/"
        var selectedAddress = UserDefaults.standard.string(forKey: "SelectedAddress")

        do {
            let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
            var ks: EthereumKeystoreV3?
            if keystoreManager?.addresses?.isEmpty ?? true {
                ks = try EthereumKeystoreV3(password: "BANKEXFOUNDATION")
                let keydata = try JSONEncoder().encode(ks!.keystoreParams)
                FileManager.default.createFile(atPath: userDir + "/keystore/" + (ks?.addresses?.first?.address ?? "") + ".json", contents: keydata, attributes: nil)
            }
            guard let sender = keystoreManager?.addresses?.first else {return}
            print(sender)
            let web3 = Web3.InfuraRinkebyWeb3()
            web3.addKeystoreManager(keystoreManager)
            
            registerCallbacks(web3)
        }
        catch{
            print(error)
        }
    }
    
    fileprivate func registerCallbacks(_ web3: web3) {
        self.webView.bridge.register({ (parameters, completion) in
            let url = web3.provider.url.absoluteString
            completion(.success(["rpcURL": url as Any]))
        }, for: "getRPCurl")
        
        self.webView.bridge.register({ (parameters, completion) in
            let allAccounts = web3.hookedFunctions.getAccounts()
            completion(.success(["accounts": allAccounts as Any]))
        }, for: "eth_getAccounts")
        
        self.webView.bridge.register({ (parameters, completion) in
            let coinbase = web3.hookedFunctions.getCoinbase()
            completion(.success(["coinbase": coinbase as Any]))
        }, for: "eth_coinbase")
        
        addHandlerToSignMessage(web3)
        addHandlerToSignTransaction(web3)
    }

    fileprivate func addHandlerToSignTransaction(_ web3: web3) {
        self.webView.bridge.register({ (parameters, completion) in
            guard let parameters = parameters else {
                completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.noParamaters.rawValue)))
                return
            }
            guard let transaction = parameters["transaction"] as? [String:Any] else {
                completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.notEnoughParameters.rawValue)))
                return
            }
            self.showConfirmation(
                for: transaction,
                confirmCallback: {
                    guard let result = web3.hookedFunctions.signTransaction(transaction) else {
                        completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.dataIsInvalid.rawValue)))
                        return
                    }
                    completion(.success(["signedTransaction": result]))
            },
                cancelCallback: {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.genericError.rawValue)))
            })
        }, for: "eth_signTransaction")
    }
    
    fileprivate func addHandlerToSignMessage(_ web3: web3) {
        self.webView.bridge.register({[weak self] (parameters, completion) in
            guard let parameters = parameters,
                let payload = parameters["payload"] as? [String:Any] else {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.noParamaters.rawValue)))
                    return
            }
            guard let personalMessage = payload["data"] as? String,
                let account = payload["from"] as? String else {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.notEnoughParameters.rawValue)))
                    return
            }
            self?.showConfirmation(for: payload, confirmCallback: {
                guard let signedResult = web3.hookedFunctions.personalSign(personalMessage, account: account) else {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.accountOrDataIsInvalid.rawValue)))
                    return
                }
                completion(.success(["signedMessage": signedResult]))
            }, cancelCallback: {
                completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.genericError.rawValue)))
            })
            }, for: "eth_sign")
    }
    
    // MARK: TextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    @IBAction func refreshPage(_ sender: Any) {
        webView.load(URLRequest(url: URL(string: "https://ownanumber.github.io/")!))
    }
    
    //MARK: - Confirmation Controller
    
    var confirmationController: ConfirmationController?
    fileprivate func showConfirmation(for transaction: [String: Any],
                                      confirmCallback: @escaping ()->Void,
                                      cancelCallback: @escaping ()->Void) {
        guard askConfirmationForSigning else {
            confirmCallback()
            return
        }
        confirmationController = nil
        confirmationController = ConfirmationController()
        confirmationController?.view.frame = (navigationController?.view.frame)!
        confirmationController?.configure(with: transaction,
                                          confirmBlock: confirmCallback,
                                          cancelBlock: cancelCallback)
        navigationController?.view.addSubview(confirmationController!.view)
        confirmationController!.view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.confirmationController!.view.alpha = 1
        }
    }
}

