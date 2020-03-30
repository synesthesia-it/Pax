//
//  ViewController.swift
//  Pax
//
//  Created by Stefano Mondino on 03/30/2020.
//  Copyright (c) 2020 Stefano Mondino. All rights reserved.
//

import UIKit
import Pax
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func showLeft(_ sender: Any) {
        pax.controller?.showLeftViewController(animated: true)
    }
    @IBAction func showRight(_ sender: Any) {
        pax.controller?.showRightViewController(animated: true)
    }
    @IBAction func openRed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "red")
        pax.controller?.setMainViewController(vc, animated: true)

        vc.pax.mainEffect = { percentage, viewController in
            //A completely pointless main controller transition
            let transform = CATransform3DMakeRotation( -percentage * CGFloat.pi / 4, 0, 0, 1)
            viewController.view.layer.zPosition = -1
            viewController.view.layer.transform = transform
        }
    }
    @IBAction func backToStart(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "navigationController")
        pax.controller?.setMainViewController(vc, animated: true)
    }
}

