//
//  ViewController.swift
//  Demo
//
//  Created by Stefano Mondino on 05/01/17.
//  Copyright © 2017 Synesthesia. All rights reserved.
//

import UIKit
import Pax

class PaxController: Pax {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mode = .onTop
        let main = UINavigationController(rootViewController: Center())
        let menu = Menu()
        let other = Menu()
        self.setMainViewController(main)
        //self.rightViewController = other
        self.leftViewController = menu
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class Menu: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pax_width = 300
        self.view.layer.borderColor = UIColor.black.cgColor
        self.view.layer.borderWidth = 20
        self.view.backgroundColor = UIColor.orange.withAlphaComponent(1.5)
    }
}

class Center: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        let item = UIBarButtonItem(title: "menu", style: .done, target: self, action: #selector(showLeftMenu))
        self.navigationItem.leftBarButtonItem = item
    }
}
