//
//  SettingsController.swift
//  web3swiftBrowser
//
//  Created by Korovkina, Ekaterina (Agoda) on 2/18/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import UIKit
import web3swift

class SettingsController: UITableViewController {

    var numberOfRowsToShow = 0
    var addresses: [EthereumAddress]?
    var selectedAddress = UserDefaults.standard.string(forKey: "SelectedAddress")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Do any additional setup after loading the view.
        let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
        
        addresses = keystoreManager?.addresses
        guard let _ = selectedAddress else {
            selectedAddress = addresses?.first?.address
            return
        }
        tableView.reloadData()
    }
    
    // MARK: - TableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        if index < (addresses?.count ?? 0) {
            selectedAddress = addresses?[index].address
            UserDefaults.standard.set(selectedAddress, forKey: "SelectedAddress")
        }
        tableView.reloadData()
    }
    
    // MARK - TableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        if index == (addresses?.count ?? 0) {
            return tableView.dequeueReusableCell(withIdentifier: "CreateNewKey")!
        }
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
        let addressAtIndex = (index < addresses?.count ?? 0) ? addresses?[indexPath.row].address : nil
        cell.textLabel?.text = addressAtIndex ?? "Create New Key"
        cell.backgroundColor = UIColor.clear
        if addressAtIndex == selectedAddress {
            cell.imageView?.image = #imageLiteral(resourceName: "icons-checked")
        }
        return cell
    }
//
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (addresses?.count ?? 0) + 1
    }

}
