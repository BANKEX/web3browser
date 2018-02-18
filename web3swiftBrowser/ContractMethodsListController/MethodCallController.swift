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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let abiToCall = abiToCall else {return 0}
        // #warning Incomplete implementation, return the number of rows
        switch abiToCall {
        case .function(let abiFunc):
            numberOfItems = (abiFunc.inputs.count == 0) ? 1 : abiFunc.inputs.count + 2
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
//            case .constructor(let construct):
//            case .event(let event):
//            case .fallback(let fallback):
            default:
                cell.parameterNameLabel.text = ""
            }
            return cell
        }
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
