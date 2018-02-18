//
//  ContractMethodsListController.swift
//  web3swiftBrowser
//
//  Created by Korovkina, Ekaterina (Agoda) on 2/18/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import UIKit
import web3swift
import BigInt

class ContractMethodsListController: UITableViewController {
    
    let contractAddress = ""
    
    
    var contractToShow: Contract?
    var keysOfMethods = [String]()
    var selectedMethod: String?
    var didUpdate = false
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        selectedMethod = nil
//    }
//
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectedMethod = nil
        guard !didUpdate else {
        return
        }
        didUpdate = true
//        let localweb3 = Web3.newWeb3(URL(string: "http://localhost:8545")!)
//        let accounts = localweb3!.eth.getAccounts()
        let pathToFile = Bundle.main.path(forResource: "DefaultContract", ofType: "json")
        let jsonString = try! String(contentsOfFile: pathToFile!)
        do {
            let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
            var ks: EthereumKeystoreV3?
            if (keystoreManager?.addresses?.count == 0) {
                ks = try EthereumKeystoreV3(password: "BANKEXFOUNDATION")
                let keydata = try JSONEncoder().encode(ks!.keystoreParams)
                FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keydata, attributes: nil)
            } else {
                ks = keystoreManager?.walletForAddress((keystoreManager?.addresses![0])!) as! EthereumKeystoreV3
            }
            guard let sender = ks?.addresses?.first else {return}
            print(sender)
            
            // BKX TOKEN
            let coldWalletAddress = EthereumAddress("0x6394b37Cf80A7358b38068f0CA4760ad49983a1B")
            let constractAddress = EthereumAddress("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
            var options = Web3Options()
            options.gas = BigUInt(250000)
            options.gasPrice = BigUInt(25000000000)
            options.from = EthereumAddress("0xE6877A4d8806e9A9F12eB2e8561EA6c1db19978d")
            let parameters = [] as [AnyObject]
            let web3Main = Web3.InfuraMainnetWeb3()
            web3Main.addKeystoreManager(keystoreManager)
            let contract = web3Main.contract(jsonString, at: constractAddress)
            let intermediate = contract?.method("name", parameters:parameters,  options: options)
            contractToShow = contract?.contract
            for (key, _) in contractToShow?.methods ?? [:] {
                keysOfMethods.append(key)
            }
            var res = intermediate?.call(options: options)
            guard let result = res else {return}
            print("BKX token name = " + (result["0"] as! String))
            
            let bkxBalance = contract?.method("balanceOf", parameters: [coldWalletAddress] as [AnyObject], options: options)?.call(options: nil)
            guard let bkx = bkxBalance, let bal = bkx["0"] as? BigUInt else {return}
            print("BKX token balance = " + String(bal))
            let erc20receipt = web3Main.eth.getTransactionReceipt("0x76bb19c0b7e2590f724871960599d28db99cd587506fdfea94062f9c8d61eb30")
            for l in (erc20receipt?.logs)! {
                guard let result = contract?.parseEvent(l), let name = result.eventName, let data = result.eventData else {continue}
                print("Parsed event " + name)
                print("Parsed content")
                print(data)
            }
            // Block number on Main
            
            let blockNumber = web3Main.eth.getBlockNumber()
            print("Block number = " + String(blockNumber!))
            
            
            let gasPrice = web3Main.eth.getGasPrice()
            print("Gas price = " + String(gasPrice!))
            
            
            //Send on Rinkeby
            
            let web3Rinkeby = Web3.InfuraRinkebyWeb3()
            web3Rinkeby.addKeystoreManager(keystoreManager)
            let coldWalletABI = "[{\"payable\":true,\"type\":\"fallback\"}]"
            
            options = Web3Options.defaultOptions()
            options.gas = BigUInt(21000)
            options.from = ks?.addresses?.first!
            options.value = BigUInt(1000000000000000)
            options.from = sender
            var estimatedGas = web3Rinkeby.contract(coldWalletABI, at: coldWalletAddress)?.method(options: options)?.estimateGas(options: nil)
            options.gas = estimatedGas
            var intermediateSend = web3Rinkeby.contract(coldWalletABI, at: coldWalletAddress)?.method(options: options)
            res = intermediateSend?.send(password: "BANKEXFOUNDATION")
            let derivedSender = intermediateSend?.transaction.sender
            if (derivedSender?.address != sender.address) {
                print(derivedSender!.address)
                print(sender.address)
                print("Address mismatch")
            }
//            let txid = res!["txhash"] as? String
//            print("On Rinkeby TXid = " + txid!)
//            
//            //Balance on Rinkeby
//            let balance = web3Rinkeby.eth.getBalance(address: coldWalletAddress)
//            print("Balance of " + coldWalletAddress.address + " = " + String(balance!))
            
            
            //                Send mutating transaction taking parameters
            let testABIonRinkeby = "[{\"constant\":true,\"inputs\":[],\"name\":\"counter\",\"outputs\":[{\"name\":\"\",\"type\":\"uint8\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_value\",\"type\":\"uint8\"}],\"name\":\"increaseCounter\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"}]"
            let deployedTestAddress = EthereumAddress("0x1e528b190b6acf2d7c044141df775c7a79d68eba")
            options = Web3Options.defaultOptions()
            options.gas = BigUInt(100000)
            options.value = BigUInt(0)
            options.from = ks?.addresses![0]
            let testParameters = [BigUInt(1)] as [AnyObject]
            estimatedGas = web3Rinkeby.contract(testABIonRinkeby, at: deployedTestAddress)?.method("increaseCounter", parameters: testParameters, options: options)?.estimateGas(options: nil)
            options.gas = estimatedGas
            let testMutationResult = web3Rinkeby.contract(testABIonRinkeby, at: deployedTestAddress)?.method("increaseCounter", parameters: testParameters, options: options)?.send(password: "BANKEXFOUNDATION")
            
            print(testMutationResult)
            //get TX details
            
            let details = web3Rinkeby.eth.getTransactionDetails("0x8ef43236af52e344353590c54089d5948e2182c231751ac1fb370409fdd0c76a")
            
            print(details)
            var receipt = web3Rinkeby.eth.getTransactionReceipt("0x8ef43236af52e344353590c54089d5948e2182c231751ac1fb370409fdd0c76a")
            print(receipt)
            receipt =  web3Rinkeby.eth.getTransactionReceipt("0x5f36355eae23e164003753f6e794567f963a658effab922620bb64459f130e1e")
            print(receipt)
            
        }
        catch{
            print(error)
        }
        tableView.reloadData()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contractToShow?.methods.count ?? 0
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "reuseIdentifier")
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.text = keysOfMethods[indexPath.row]
        return cell
     }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMethod = keysOfMethods[indexPath.row]
        performSegue(withIdentifier: "showMethodParamters", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMethodParamters" {
            guard let controller = segue.destination as? MethodCallController else {
                return
            }
            controller.abiToCall = contractToShow?.methods[selectedMethod ?? ""]
            controller.title = selectedMethod ?? ""
        }
    }
 
    
}
