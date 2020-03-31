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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func showLeft(_ sender: Any) {
        pax.controller?.showViewController(at: .left, animated: true)
    }
    @IBAction func showRight(_ sender: Any) {
        pax.controller?.showViewController(at: .right, animated: true)
    }
    @IBAction func openRed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "red")
        pax.controller?.setMainViewController(vc, animated: true)

        vc.pax.mainEffect = { percentage, viewController, side in
            let width = (viewController.pax.controller?.viewController(at: side)?.pax.menuWidth ?? 0)
            let direction: CGFloat = side == .left ? 1 : -1
            let transform = CATransform3DMakeTranslation(percentage * width * direction , 0, 0)
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
