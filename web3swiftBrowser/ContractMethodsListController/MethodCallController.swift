//
//  MethodCallController.swift
//  web3swiftBrowser
//
//  Created by Korovkina, Ekaterina (Agoda) on 2/18/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import UIKit
import web3swift

class MethodCallController: UITableViewController {

    var abiToCall: ABIElement?
    var numberOfItems = 0
    
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
        case .constructor(let constructor):
            numberOfItems = (constructor.inputs.count == 0) ? 1 : constructor.inputs.count + 2
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
                cell.parameterNameLabel.text = function.inputs[indexPath.row - 1].name
            case .constructor(let construct):
                cell.parameterNameLabel.text = construct.inputs[indexPath.row - 1].name
            case .event(let event):
                cell.parameterNameLabel.text = event.inputs[indexPath.row - 1].name
            default:
                cell.parameterNameLabel.text = ""
            }
            return cell
        }
    }

}
