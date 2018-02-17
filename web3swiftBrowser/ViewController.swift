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
    case dataIsInvalid = ""
}

class BrowserViewController: UIViewController {
    
    enum Method: String {
        case getAccounts
        case signTransaction
        case signMessage
        case signPersonalMessage
        case publishTransaction
        case approveTransaction
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
        do {
            let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
            var ks: EthereumKeystoreV3?
            if (keystoreManager?.addresses?.count == 0) {
                ks = try EthereumKeystoreV3(password: "BANKEXFOUNDATION")
                let keydata = try JSONEncoder().encode(ks!.keystoreParams)
                FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keydata, attributes: nil)
            }
            guard let sender = keystoreManager?.addresses?.first else {return}
            print(sender)
            let web3 = Web3.InfuraRinkebyWeb3()
            web3.addKeystoreManager(keystoreManager)
            
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
            
            self.webView.bridge.register({ (parameters, completion) in
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
                let result = web3.hookedFunctions.personalSign(personalMessage, account: account)
                if result == nil {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.accountOrDataIsInvalid.rawValue)))
                    return
                }
                completion(.success(["signedMessage": result as Any]))
            }, for: "eth_sign")
            
            self.webView.bridge.register({ (parameters, completion) in
                guard let parameters = parameters else {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.noParamaters.rawValue)))
                    return
                }
                
                guard let transaction = parameters["transaction"] as? [String:Any] else {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.notEnoughParameters.rawValue)))
                    return
                }
                
                guard let result = web3.hookedFunctions.signTransaction(transaction) else {
                    completion(.failure(Bridge.JSError(code: 0, description: JSRequestsError.dataIsInvalid.rawValue)))
                    return
                }
                completion(.success(["signedTransaction": result as Any]))
            }, for: "eth_signTransaction")
        }
        catch{
            print(error)
        }
    }
}
