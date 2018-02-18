//
//  MethodCallController.swift
//  web3swiftBrowser
//
//  Created by Korovkina, Ekaterina (Agoda) on 2/18/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import UIKit
import web3swift
import BigInt

class MethodCallController: UITableViewController {

    var abiToCall: ABIElement?
    var numberOfItems = 0
    var textFields = [String: UITextField]()
    var contract: Contract?
    var fullContract: web3.web3contract?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let abiToCall = abiToCall else {return 0}
        // #warning Incomplete implementation, return the number of rows
        switch abiToCall {
        case .function(let abiFunc):
            numberOfItems = (abiFunc.inputs.count == 0) ? 1 : abiFunc.inputs.count + 2
            numberOfItems += abiFunc.payable ? 1 : 0
        case .constructor(let constructor):
            numberOfItems = (constructor.inputs.count == 0) ? 1 : constructor.inputs.count + 2
            numberOfItems += constructor.payable ? 1 : 0
        case .fallback(let fallback):
            numberOfItems = 0
        case .event(let event):
            numberOfItems = (event.inputs.count == 0) ? 1 : event.inputs.count + 2
        default:
            return 0
        }
        return numberOfItems
    }

    
    let firstCellId = "ParametersList"
    let inputDataCellId = "ParamterInput"
    let callMethodCellId = "CallMethod"
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let abiToCall = abiToCall else {
            return tableView.dequeueReusableCell(withIdentifier: firstCellId)!
        }
        if numberOfItems == 1 {
            return tableView.dequeueReusableCell(withIdentifier: callMethodCellId)!
        }
        else if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: firstCellId)!
        } else if indexPath.row == numberOfItems - 1 {
            return tableView.dequeueReusableCell(withIdentifier: callMethodCellId)!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: inputDataCellId) as! InputParameterCell
            switch abiToCall {
            case .function(let function):
                if indexPath.row - 1 == function.inputs.count && function.payable {
                    cell.parameterNameLabel.text = "_value"
                } else {
                    cell.parameterNameLabel.text = function.inputs[indexPath.row - 1].name
                }
            case .constructor(let construct):
                if indexPath.row - 1 == construct.inputs.count && construct.payable {
                    cell.parameterNameLabel.text = "_value"
                } else {
                    cell.parameterNameLabel.text = construct.inputs[indexPath.row - 1].name
                }
            case .event(let event):
                cell.parameterNameLabel.text = event.inputs[indexPath.row - 1].name
            default:
                cell.parameterNameLabel.text = ""
            }
            textFields[cell.parameterNameLabel.text!] = cell.parameterValueTextField
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == numberOfItems - 1,
            let abiToCall = abiToCall else {return}
        
        var parameters = [AnyObject]()
        switch abiToCall {
        case .function(let function):
            for nextInput in function.inputs {
                let textField = textFields[nextInput.name]
                guard let text = textField?.text else {
                    return
                }
                if nextInput.name == "_from" ||
                    nextInput.name == "_to" ||
                    nextInput.name == "_owner" ||
                    nextInput.name == "_spender" {
                    parameters.append(EthereumAddress(text) as AnyObject)
                }
                if nextInput.name == "_value" {
                    guard let amount = UInt(text) else {
                        return
                    }
                    parameters.append(BigUInt(amount) as AnyObject)
                } else if nextInput.name == "_extraData" {
                    guard let data = Data.fromHex(text) else {return}
                    parameters.append(data as AnyObject)
                }
            }
//            if indexPath.row - 1 == function.inputs.count && function.payable {
//                cell.parameterNameLabel.text = "_value"
//            } else {
//                cell.parameterNameLabel.text = function.inputs[indexPath.row - 1].name
//            }
//        case .constructor(let construct):
//            if indexPath.row - 1 == construct.inputs.count && construct.payable {
//                cell.parameterNameLabel.text = "_value"
//            } else {
//                cell.parameterNameLabel.text = construct.inputs[indexPath.row - 1].name
//            }
//        case .event(let event):
//            cell.parameterNameLabel.text = event.inputs[indexPath.row - 1].name
        default:
            let i = 1;
        }
        print("\(parameters)")
        
        var options = Web3Options()
        options.gas = BigUInt(250000)
        options.gasPrice = BigUInt(25000000000)
        options.from = EthereumAddress("0xE6877A4d8806e9A9F12eB2e8561EA6c1db19978d")
        let bkxBalance = fullContract?.method(title ?? "", parameters: parameters, options: options)?.call(options: nil)
        print("\(bkxBalance)")
    }
}
