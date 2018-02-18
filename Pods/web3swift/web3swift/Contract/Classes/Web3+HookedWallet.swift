//
//  Web3+HookedWallet.swift
//  web3swift
//
//  Created by Alexander Vlasov on 07.01.2018.
//

import Foundation
import BigInt

extension web3.HookedFunctions {
    
    public func getAccounts() -> [String]? {
        guard let keystoreManager = self.web3?.provider.attachedKeystoreManager else {return nil}
        guard let ethAddresses = keystoreManager.addresses else {return nil}
        return ethAddresses.flatMap({$0.address})
    }
    
    public func getCoinbase() -> String? {
        guard let addresses = self.getAccounts() else {return nil}
        guard addresses.count > 0 else {return nil}
        return addresses[0]
    }
    
    public func personalSign(_ personalMessage: String, account: String, password: String = "BANKEXFOUNDATION") -> String? {
        return self.sign(personalMessage, account: account, password: password)
    }
    
    public func sign(_ personalMessage: String, account: String, password: String = "BANKEXFOUNDATION") -> String? {
        guard let data = Data.fromHex(personalMessage) else {return nil}
        return self.sign(data, account: account, password: password)
    }
    
    public func sign(_ personalMessage: Data, account: String, password: String = "BANKEXFOUNDATION") -> String? {
        do {
            guard let keystoreManager = self.web3?.provider.attachedKeystoreManager else {return nil}
            guard let signature = try keystoreManager.signPersonalMessage(personalMessage, password: password, account: EthereumAddress(account)) else {return nil}
            guard let sender = self.personalECRecover(personalMessage, signature: signature) else {return nil}
            print(sender)
            if sender.lowercased() != account.lowercased() {
                print("Invalid sender")
            }
            return signature.toHexString().addHexPrefix()
        }
        catch{
            print(error)
            return nil
        }
    }
    
    public func personalECRecover(_ personalMessage: String, signature: String) -> String? {
        guard let data = Data.fromHex(personalMessage) else {return nil}
        guard let sig = Data.fromHex(signature) else {return nil}
        return self.personalECRecover(data, signature:sig)
    }
    
    public func personalECRecover(_ personalMessage: Data, signature: Data) -> String? {
        if signature.count != 65 { return nil}
        let rData = signature[0..<32].bytes
        let sData = signature[32..<64].bytes
        let vData = signature[64]
        guard let signatureData = SECP256K1.marshalSignature(v: vData, r: rData, s: sData) else {return nil}
        var hash: Data
        if personalMessage.count == 32 {
            print("Most likely it's hash already, allow for now")
            hash = personalMessage
        } else {
            guard let h = Web3.Utils.hashPersonalMessage(personalMessage) else {return nil}
            hash = h
        }
        guard let publicKey = SECP256K1.recoverPublicKey(hash: hash, signature: signatureData) else {return nil}
        return Web3.Utils.publicToAddressString(publicKey)
    }
    
    
    public func sendTransaction(_ transactionJSON: [String: Any], password: String = "BANKEXFOUNDATION") -> [String:Any]? {
        guard let transaction = EthereumTransaction.fromJSON(transactionJSON) else {return nil}
        guard let options = Web3Options.fromJSON(transactionJSON) else {return nil}
        return self.sendTransaction(transaction, options: options, password: password)
    }
    
    public func sendTransaction(_ trans: EthereumTransaction, options: Web3Options, password: String = "BANKEXFOUNDATION") -> [String:Any]? {
        do {
            var transaction = trans
            guard let from = options.from else {return nil}
            guard let keystoreManager = self.web3?.provider.attachedKeystoreManager else {return nil}
            guard let nonce = self.web3?.eth.getTransactionCount(address: from, onBlock: "pending") else {return nil}
            transaction.nonce = nonce
            if (self.web3?.provider.network != nil) {
                transaction.chainID = self.web3?.provider.network?.chainID
            }
            try keystoreManager.signTX(transaction: &transaction, password: password, account: from)
            print(transaction)
            guard let request = EthereumTransaction.createRawTransaction(transaction: transaction) else {return nil}
            let response = self.web3?.provider.sendSync(request: request)
            if response == nil {
                return nil
            }
            guard let res = response else {return nil}
            if let error = res["error"] as? String {
                print(error as String)
                return nil
            }
            guard let resultString = res["result"] as? String else {return nil}
            let hash = resultString.addHexPrefix().lowercased()
            return ["txhash": hash as Any, "txhashCalculated" : transaction.txhash as Any]
        }
        catch {
            return nil
        }
    }
    
    public func estimateGas(_ transactionJSON: [String: Any]) -> BigUInt? {
        guard let transaction = EthereumTransaction.fromJSON(transactionJSON) else {return nil}
        guard let options = Web3Options.fromJSON(transactionJSON) else {return nil}
        return self.estimateGas(transaction, options: options)
    }
    
    public func estimateGas(_ transaction: EthereumTransaction, options: Web3Options) -> BigUInt? {
        return self.web3?.eth.estimateGas(transaction, options: options)
    }
    
    
    public func prepareTxForApproval(_ transactionJSON: [String: Any]) -> (transaction: EthereumTransaction?, options: Web3Options?) {
        guard let transaction = EthereumTransaction.fromJSON(transactionJSON) else {return (nil, nil)}
        guard let options = Web3Options.fromJSON(transactionJSON) else {return (nil, nil)}
        return self.prepareTxForApproval(transaction, options: options)
    }
    
    public func prepareTxForApproval(_ trans: EthereumTransaction, options  opts: Web3Options) -> (transaction: EthereumTransaction?, options: Web3Options?) {
        var transaction = trans
        var options = opts
        guard let from = options.from else {return (nil, nil)}
        guard let keystoreManager = self.web3?.provider.attachedKeystoreManager else {return (nil, nil)}
        guard let _ = keystoreManager.walletForAddress(from) else {return (nil, nil)}
        
        guard let gasPrice = self.web3?.eth.getGasPrice() else {return (nil, nil)}
        transaction.gasPrice = gasPrice
        options.gasPrice = gasPrice
        guard let gasEstimate = self.estimateGas(transaction, options: options) else {return (nil, nil)}
        transaction.gasLimit = gasEstimate
        options.gas = gasEstimate
        print(transaction)
        return (transaction, options)
    }
    
    public func signPreparedTransaction(_ trans: EthereumTransaction, options: Web3Options, password: String = "BANKEXFOUNDATION") -> String? {
        do {
            var transaction = trans
            guard let from = options.from else {return nil}
            guard let keystoreManager = self.web3?.provider.attachedKeystoreManager else {return nil}
            guard let nonce = self.web3?.eth.getTransactionCount(address: from, onBlock: "pending") else {return nil}
            transaction.nonce = nonce
            if (self.web3?.provider.network != nil) {
                transaction.chainID = self.web3?.provider.network?.chainID
            }
            guard let keystore = keystoreManager.walletForAddress(from) else {return nil}
            try keystore.signTX(transaction: &transaction, password: password, account: from)
            print(transaction)
            let signedData = transaction.encode(forSignature: false, chainID: nil)?.toHexString().addHexPrefix()
            return signedData
        }
        catch {
            return nil
        }
    }
    
    
    public func signTransaction(_ transactionJSON: [String: Any], password: String = "BANKEXFOUNDATION") -> String? {
        guard let transaction = EthereumTransaction.fromJSON(transactionJSON) else {return nil}
        guard let options = Web3Options.fromJSON(transactionJSON) else {return nil}
        return self.signTransaction(transaction, options: options, password: password)
    }
    
    public func signTransaction(_ trans: EthereumTransaction, options: Web3Options, password: String = "BANKEXFOUNDATION") -> String? {
        do {
            var transaction = trans
            guard let from = options.from else {return nil}
            guard let keystoreManager = self.web3?.provider.attachedKeystoreManager else {return nil}
            
            guard let gasPrice = self.web3?.eth.getGasPrice() else {return nil}
            transaction.gasPrice = gasPrice
            
            guard let gasEstimate = self.estimateGas(transaction, options: options) else {return nil}
            transaction.gasLimit = gasEstimate
            
            guard let nonce = self.web3?.eth.getTransactionCount(address: from, onBlock: "pending") else {return nil}
            transaction.nonce = nonce
            if (self.web3?.provider.network != nil) {
                transaction.chainID = self.web3?.provider.network?.chainID
            }
            guard let keystore = keystoreManager.walletForAddress(from) else {return nil}
            try keystore.signTX(transaction: &transaction, password: password, account: from)
            print(transaction)
            let signedData = transaction.encode(forSignature: false, chainID: nil)?.toHexString().addHexPrefix()
            return signedData
        }
        catch {
            return nil
        }
    }
}
