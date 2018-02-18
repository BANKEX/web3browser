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
            numberOfItems = (abiFunc.inputs.count == 0 && !abiFunc.payable) ? 1 : abiFunc.inputs.count + 2
            numberOfItems += abiFunc.payable ? 1 : 0
        case .constructor(let constructor):
            numberOfItems = (constructor.inputs.count == 0 && !constructor.payable) ? 1 : constructor.inputs.count + 2
            numberOfItems += constructor.payable ? 1 : 0
        case .fallback(let fallback):
            numberOfItems = 0
        case .event(let event):
            numberOfItems = (event.inputs.count == 0) ? 1 : event.inputs.count + 2
        default:
            return 0
        }
        numberOfItems += (result.count > 0 ? 1 : 0)
        return numberOfItems
    }

    
    let firstCellId = "ParametersList"
    let inputDataCellId = "ParamterInput"
    let callMethodCellId = "CallMethod"
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let abiToCall = abiToCall else {
            return tableView.dequeueReusableCell(withIdentifier: firstCellId)!
        }
        if numberOfItems == 1 &&  result.count == 0 ||
            numberOfItems == 2 && result.count > 0 {
            if indexPath.row == 0 {
                return tableView.dequeueReusableCell(withIdentifier: callMethodCellId)!
            }
            else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: "smth")
                cell.textLabel?.text = result
                cell.backgroundColor = UIColor.clear
                return cell
            }
        }
        else if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: firstCellId)!
        } else if (indexPath.row == numberOfItems - 2 && result.count > 0) ||
            (indexPath.row == numberOfItems - 1 && result.count == 0)  {
            return tableView.dequeueReusableCell(withIdentifier: callMethodCellId)!
        } else if indexPath.row == numberOfItems - 1 && result.count > 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "smth")
            cell.textLabel?.text = result
            cell.backgroundColor = UIColor.clear
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: inputDataCellId) as! InputParameterCell
            switch abiToCall {
            case .function(let function):
                if indexPath.row - 1 == function.inputs.count && function.payable {
                    cell.parameterNameLabel.text = "_value"
                    cell.parameterValueTextField.placeholder = ""
                } else {
                    cell.parameterNameLabel.text = function.inputs[indexPath.row - 1].name
                    cell.parameterValueTextField.placeholder = function.inputs[indexPath.row - 1].type.abiRepresentation
                }
            case .constructor(let construct):
                if indexPath.row - 1 == construct.inputs.count && construct.payable {
                    cell.parameterNameLabel.text = "_value"
                } else {
                    cell.parameterNameLabel.text = construct.inputs[indexPath.row - 1].name
                    cell.parameterValueTextField.placeholder = construct.inputs[indexPath.row - 1].type.abiRepresentation
                }
            case .event(let event):
                cell.parameterNameLabel.text = event.inputs[indexPath.row - 1].name
                cell.parameterValueTextField.placeholder = event.inputs[indexPath.row - 1].type.abiRepresentation
            default:
                cell.parameterNameLabel.text = ""
            }
            let key = cell.parameterNameLabel.text!.count > 0 ? cell.parameterNameLabel.text! : "\(indexPath.row - 1)"
            textFields[key] = cell.parameterValueTextField
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == numberOfItems - 1,
            let abiToCall = abiToCall else {return}
//        result = ""
//        tableView.reloadData()
        var i = 0
        var options = Web3Options()

        var parameters = [AnyObject]()
        var isMutating = false
        
        switch abiToCall {
        case .function(let function):
//            isMutating = !function.constant
            for nextInput in function.inputs {
                var key = nextInput.name
                if key.count == 0 {
                    key = "\(i)"
                    i += 1
                }
                let textField = textFields[key]
                guard let text = textField?.text else {
                    return
                }
                if nextInput.name == "_from" ||
                    nextInput.name == "_to" ||
                    nextInput.name == "_owner" ||
                    nextInput.name == "_spender" ||
                    nextInput.name == "_user" ||
                    nextInput.type.abiRepresentation.hasPrefix("address") {
                    parameters.append(EthereumAddress(text) as AnyObject)
                }
                if nextInput.name == "_value" {
                    guard let amount = UInt(text) else {
                        return
                    }
                    parameters.append(BigUInt(amount) as AnyObject)
                } else if nextInput.name == "_extraData" ||
                    nextInput.type.abiRepresentation.hasPrefix("bytes") {
                    guard let data = Data.fromHex(text) else {return}
                    parameters.append(data as AnyObject)
                } else if nextInput.type.abiRepresentation.hasPrefix("uint") {
                    let characters = Array(text.flatMap{UInt(String($0))}.reversed())
                    parameters.append(BigUInt(words: characters) as AnyObject)
                }
                else if nextInput.type.abiRepresentation.hasPrefix("int") {
                    let characters = text.flatMap{UInt(String($0))}.reversed()
                    parameters.append(BigUInt(words: characters) as AnyObject)
                }
                if function.payable {
                    guard let number = Int((textFields["_value"]?.text) ?? "") else {
                        return
                    }
                    options.value = BigUInt(number)
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
        
        options.gas = BigUInt(250000)
        options.gasPrice = BigUInt(25000000000)
        
        options.from = EthereumAddress(UserDefaults.standard.string(forKey: "SelectedAddress") ?? "")
        
        var bkxBalance: [String: Any]?
        if isMutating {
            bkxBalance = fullContract?.method(title ?? "", parameters: parameters, options: options)?.send(password: "BANKEXFOUNDATION", options: options)
        } else {
         bkxBalance = fullContract?.method(title ?? "", parameters: parameters, options: options)?.call(options: options)
        }
        var localResult = ""
        for (key, value) in bkxBalance ?? [:] {
            print("\(key) = \(value)")
            localResult += "\(key) = \(value)\n"
        }
        for (_, textfield) in textFields {
            textfield.text = ""
        }
        if localResult.count > 0 {
            let alert = UIAlertController(title: "Result", message: localResult, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Result", message: "No valid result for request", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "So sad :-(", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        tableView.reloadData()
    }
    var result = ""
}
