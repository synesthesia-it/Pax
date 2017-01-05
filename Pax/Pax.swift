//
//  Pax.swift
//  Pax
//
//  Created by Stefano Mondino on 05/01/17.
//  Copyright © 2017 Synesthesia. All rights reserved.
//

import UIKit

public enum SideMode {
    case onTop
    case fixed
}

public extension UIViewController {
    public var pax: Pax? {
        var parent:UIViewController? = self
        while (parent != nil) {
            if (parent is Pax) {
                return parent as? Pax
            }
                parent = parent?.parent
            }
        return nil
        }
    @IBAction public func showLeftMenu() {
        self.pax?.showLeftViewController(animated: true)
    }
    @IBAction public func showRightMenu() {
        self.pax?.showRightViewController(animated: true)
    }
}

extension UIView {
    func pax_centerInSuperview() {
        guard let container = self.superview else {
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        let views: [String: AnyObject] =
            ["view" : self,
             "container" : container]
        
        let h = NSLayoutConstraint.constraints(
            withVisualFormat: "|-0-[view]-0-|",
            options: [],
            metrics: nil,
            views: views)
        NSLayoutConstraint.activate(h)
        
        let v = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-[view]-|",
            options: [],
            metrics: nil,
            views: views)
        NSLayoutConstraint.activate(v)
    }
    
    func pax_alignLeft(width:CGFloat, reversed:Bool = false) -> NSLayoutConstraint? {
        guard let container = self.superview else {
            return nil
        }
        container.layoutMargins = .zero
        self.translatesAutoresizingMaskIntoConstraints = false
        let views: [String: AnyObject] =
            ["view" : self,
             "container" : container]
        
        let v = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-[view]-|",
            options: [],
            metrics: nil,
            views: views)
        NSLayoutConstraint.activate(v)
        let h = NSLayoutConstraint.constraints(
            withVisualFormat: "|-0-[view(\(width))]",
            options: [],
            metrics: nil,
            views: views)
        let left = h.first
        if (reversed) {
            
        }
        NSLayoutConstraint.activate(h)
        return left
        
    }
}

internal struct AssociatedKeys {
    static var Width = "pax_width"
}

public protocol SideViewController {
    var pax_width:CGFloat {get set}
}

extension UIViewController : SideViewController {
    open var pax_width: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.Width) as? CGFloat ?? 0.0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.Width, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

open class Pax : UIViewController , UIGestureRecognizerDelegate {
    weak var shadowView:UIView?
    public var mode:SideMode = .onTop {
        didSet {
            switch mode {
            case .fixed:
                break
            default: break
            }
        }
    }
    lazy var leftPanGestureRecognizer:UIScreenEdgePanGestureRecognizer = {
        let pan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.edges = .left
        pan.delegate = self
        return pan
    }()
    
    lazy var rightPanGestureRecognizer:UIScreenEdgePanGestureRecognizer = {
        let pan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.edges = .right
        pan.delegate = self
        return pan
    }()
    
    private var _sideAnimationDuration:CGFloat = 0.2
    var sideAnimationDuration:CGFloat {
        get {
            return _sideAnimationDuration
        }
        set {
            _sideAnimationDuration = max(0.2, newValue)
        }
    }
    
    private var _mainAnimationDuration:CGFloat = 0.2
    var mainAnimationDuration:CGFloat {
        get {
            return _mainAnimationDuration
        }
        set {
            _mainAnimationDuration = max(0.2, newValue)
        }
    }
//    init() {
//        super.init
//    }
//    required public init?(coder aDecoder: NSCoder) {
//        
//        super.init(coder: aDecoder)
//    }

    private var leftOpenPosition:CGFloat = 0.0
    private var leftClosedPosition:CGFloat = 0.0
    
    private var rightOpenPosition:CGFloat = 0.0
    private var rightClosedPosition:CGFloat = 0.0
    
    private var leftConstraint:NSLayoutConstraint?
    private var rightConstraint:NSLayoutConstraint?
    
    var shadowViewAlpha:CGFloat = 0.5 {
        didSet {
            self.shadowView?.alpha = shadowViewAlpha
        }
    }
    var shadowViewColor = UIColor.black {
        didSet {
            self.shadowView?.backgroundColor = shadowViewColor
        }
    }

    
//    private var leftWidth:CGFloat = 200 {
//        didSet {
//            self.leftOpenPosition = 0
//            self.leftClosedPosition = -(self.leftViewController?.pax_width ?? 200)
//        }
//    }
//    
//    private rightWidth:CGFloat = 200 {
//        didSet {
//            self.rightOpenPosition = self.view.frame.size.width - (self.rightViewController?.pax_width ?? 200)
//            self.rightClosedPosition = self.view.frame.size.width
//        }
//    }
    
    var leftParallaxAmount:CGFloat = 0.0
    var rightParallaxAmount:CGFloat = 0.0
    
    var shouldHideLeftViewControllerOnMainChange = false
    var shouldHideRightViewControllerOnMainChange = false
    
    var isLeftOpen:Bool {
        guard let left = self.leftViewController else {
            return false
        }
        guard let  main = self.mainViewController else {
            return false
        }
        switch self.mode {
        case .onTop:return abs(left.view.frame.origin.x - self.leftClosedPosition) > 1
        case .fixed: return abs(main.view.frame.origin.x - self.leftClosedPosition) > 1
        }
        
    }
    var isRightOpen = false
    
    var mainViewController:UIViewController?
    public var leftViewController:UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParentViewController()
            guard let leftViewController = leftViewController else {
                return
            }
            _ = leftViewController.view
            let w = leftViewController.pax_width
            
            self.addChildViewController(leftViewController)
//            leftViewController.view.frame = CGRect(x: self.leftClosedPosition, y: 0, width: w, height: self.view.frame.size.height)
            
            switch self.mode {
            case .onTop:
                self.leftOpenPosition = 0
                self.leftClosedPosition = -w
                self.view.addSubview(leftViewController.view)
                self.leftConstraint = leftViewController.view.pax_alignLeft(width: w)
                
            default:
                self.leftOpenPosition = w
                self.leftClosedPosition = 0
                if (self.mainViewController != nil) {
                    self.view.insertSubview(leftViewController.view, belowSubview:self.mainViewController!.view)
                }
                else {
                    self.view.addSubview(leftViewController.view)
                }
                _ = leftViewController.view.pax_alignLeft(width: w)
            }
            
            self.hideLeftViewController(animated: false)
            leftViewController.view.isUserInteractionEnabled = true
            leftViewController.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
            self.leftPanGestureRecognizer.isEnabled = true
        }
    }
    
    var rightViewController:UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParentViewController()
            guard let rightViewController = rightViewController else {
                return
            }
            let w = rightViewController.pax_width
            self.addChildViewController(rightViewController)
            rightViewController.view.frame = CGRect(x: -w, y: 0, width: w, height: self.view.frame.size.height)
            self.view.addSubview(rightViewController.view)
            //TODO constraint
            self.hideRightViewController(animated: false)
            rightViewController.view.isUserInteractionEnabled = true
            rightViewController.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
            self.rightPanGestureRecognizer.isEnabled = true
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupShadowView()
    }
    
    
    func setupShadowView() {
        let shadowView = UIView()
        shadowView.backgroundColor = self.shadowViewColor
        shadowView.alpha = self.shadowViewAlpha
        self.view.addSubview(shadowView)
        shadowView.pax_centerInSuperview()
        shadowView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideSideControllers))
        shadowView.addGestureRecognizer(tap)
        self.shadowView = shadowView
    }
    
    public func setMainViewController(_ mainViewController:UIViewController, animated:Bool = false) {
        let oldController = (mainViewController != self.mainViewController) ? self.mainViewController : nil
        
        let animated = oldController != nil ? animated : false
        self.mainViewController = mainViewController
        if (self.shouldHideLeftViewControllerOnMainChange) {
            self.hideLeftViewController(animated: animated)
        }
        if (self.shouldHideRightViewControllerOnMainChange) {
            self.hideRightViewController(animated: animated)
        }
        self.addChildViewController(mainViewController)
        
        switch self.mode {
            case .onTop:
                mainViewController.view.pax_centerInSuperview()
                if (oldController == nil) {
                    self.view.insertSubview(mainViewController.view, at: 0)
                } else {
                    self.view.insertSubview(mainViewController.view, aboveSubview: oldController!.view)
            }
            case .fixed:
                
                if (self.leftViewController == nil) {
                    self.view.insertSubview(mainViewController.view, at: 0)
                } else {
                    self.view.insertSubview(mainViewController.view, aboveSubview:self.leftViewController!.view)
            }
            self.leftConstraint = mainViewController.view.pax_alignLeft(width: self.view.frame.size.width)
        }
    
        let completion = {
            (finished:Bool) -> Void in
            oldController?.view.removeFromSuperview()
            oldController?.removeFromParentViewController()
        }
        if (animated) {
            mainViewController.view.alpha = 0
            UIView.animate(withDuration: TimeInterval(self.mainAnimationDuration), animations: { 
                mainViewController.view.alpha = 1
            }, completion:completion)
        }
        else {
            completion(true)
        }
        mainViewController.view.addGestureRecognizer(self.leftPanGestureRecognizer)
        mainViewController.view.addGestureRecognizer(self.rightPanGestureRecognizer)
    }
    
    
    
    func hideSideControllers() {
        if (self.isLeftOpen) {
            self.hideLeftViewController(animated: true)
        }
        if (self.isRightOpen) {
            self.hideRightViewController(animated: true)
        }
    }
    
    func showLeftViewController(animated:Bool) {
        guard let leftViewController = self.leftViewController else {
            return
        }
        let view = leftViewController.view
        
        guard let left = self.leftConstraint else {
            return
        }
        
        let shadowView = self.shadowView
        shadowView?.isHidden = false
        left.constant = self.leftOpenPosition
        let shadowViewAlpha = self.shadowViewAlpha
        
        let animations = {
            view?.superview?.layoutIfNeeded()
            shadowView?.alpha = shadowViewAlpha
        }
        let completion = { (finished:Bool) -> Void in
            return
        }
        if (animated) {
            UIView.animate(withDuration: TimeInterval(self.sideAnimationDuration), animations: animations, completion: completion)
        }
        else {
            animations()
            completion(true)
        }
        
        
    }
    func hideLeftViewController(animated:Bool) {
        guard let leftViewController = self.leftViewController else {
            return
        }
        let view = leftViewController.view
        
        guard let left = self.leftConstraint else {
            return
        }

        guard let shadowView = self.shadowView else {
            return
        }
        left.constant = self.leftClosedPosition
        
        let animations = {
            view?.superview?.layoutIfNeeded()
            shadowView.alpha = 0
        }
        let completion = { (finished:Bool) -> Void in
            view?.setNeedsUpdateConstraints()
            view?.updateConstraintsIfNeeded()
            if (finished == true) {
                shadowView.isHidden = true
            }
        }
        if (animated) {
            UIView.animate(withDuration: TimeInterval(self.sideAnimationDuration), animations: animations, completion: completion)
        }
        else {
            animations()
            completion(true)
        }
    }
    
    func showRightViewController(animated:Bool) {
        
    }
    func hideRightViewController(animated:Bool) {
        
    }
    func handlePan(_ panGesture:UIPanGestureRecognizer) {
        
    }
}
