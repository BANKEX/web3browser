//
//  ConfirmationController.swift
//  web3swiftBrowser
//
//  Created by Korovkina, Ekaterina (Agoda) on 2/17/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import UIKit

class ConfirmationController: UIViewController {

    @IBOutlet var toTextLabel: UILabel!
    @IBOutlet var fromTextLabel: UILabel!
    @IBOutlet fileprivate weak var valueTextLabel: UILabel!
    @IBOutlet fileprivate weak var dataTextLabel: UILabel!

    var confirmationBlock: () -> Void = {}
    var cancelBlock: () -> Void = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configure(with transaction: [String:  Any],
                   confirmBlock: @escaping ()->Void,
                   cancelBlock: @escaping () -> Void) {
        let to = transaction["to"] as? String
        let from = transaction["from"] as? String
        let value = transaction["value"] as? String
        let data = transaction["data"] as? String
        
        toTextLabel.text = to
        fromTextLabel.text = from
        valueTextLabel.text = value
        dataTextLabel.text = data
        self.confirmationBlock = confirmBlock
        self.cancelBlock = cancelBlock
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        cancelBlock()
        hideController()
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        confirmationBlock()
        hideController()
    }
    
    @IBAction func hideController(_ sender: Any) {
        cancelBlock()
        hideController()
    }
    
    fileprivate func hideController() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0
        }) { (_) in
            self.view.removeFromSuperview()
        }
    }
}
