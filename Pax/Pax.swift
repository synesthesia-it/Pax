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
    case fixedLeft
    case fixedRight
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
    
    public var sideMenuController:Pax? {return self.pax}
    
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
    
    func pax_alignLeft(width:CGFloat) -> NSLayoutConstraint? {
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
        NSLayoutConstraint.activate(h)
        return left
    }
    func pax_alignRight(width:CGFloat) -> NSLayoutConstraint? {
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
            withVisualFormat: "[view(\(width))]-0-|",
            options: [],
            metrics: nil,
            views: views)
        let right = h.last
        NSLayoutConstraint.activate(h)
        return right
    }
}

internal struct AssociatedKeys {
    static var Width = "pax_width"
}



extension UIViewController  {
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
    
    private var shadowView:UIView?
    
    public var mode:SideMode = .onTop {
        didSet {
            switch mode {
            case .fixedLeft, .fixedRight:
                self.shadowView?.removeFromSuperview()
                break
            default: break
            }
            self.setupShadowView()
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
        case .onTop, .fixedRight:return abs(left.view.frame.origin.x - self.leftClosedPosition) > 1
        case .fixedLeft: return abs(main.view.frame.origin.x - self.leftClosedPosition) > 1
        }
        
    }
    var isRightOpen:Bool {
        guard let right = self.rightViewController else {
            return false
        }
        guard let  main = self.mainViewController else {
            return false
        }
        switch self.mode {
        case .onTop, .fixedLeft:return abs(right.view.frame.origin.x - self.rightClosedPosition) > 1
        case .fixedRight: return abs(main.view.frame.origin.x - self.rightClosedPosition) > 1
        }
        
    }
    
    fileprivate var panningView:UIView?
    
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
            case .onTop, .fixedRight:
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
    
    public var rightViewController:UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParentViewController()
            guard let rightViewController = rightViewController else {
                return
            }
            _ = rightViewController.view
            let w = rightViewController.pax_width
            
            self.addChildViewController(rightViewController)
            //            leftViewController.view.frame = CGRect(x: self.leftClosedPosition, y: 0, width: w, height: self.view.frame.size.height)
            
            switch self.mode {
            case .onTop, .fixedLeft:
                self.rightOpenPosition = 0//self.view.frame.size.width - rightViewController.pax_width
                self.rightClosedPosition = -rightViewController.pax_width//self.view.frame.size.width
                self.view.addSubview(rightViewController.view)
                self.rightConstraint = rightViewController.view.pax_alignRight(width: w)
                
            default:
                self.rightOpenPosition = w
                self.rightClosedPosition = 0
                if (self.mainViewController != nil) {
                    self.view.insertSubview(rightViewController.view, belowSubview:self.mainViewController!.view)
                }
                else {
                    self.view.addSubview(rightViewController.view)
                }
                _ = rightViewController.view.pax_alignRight(width: w)
            }
            
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
        if (self.isViewLoaded == false) {
            return
        }
        let prevAlpha = self.shadowView?.alpha ?? 0.0
        self.shadowView?.removeFromSuperview()
        let shadowView = UIView()
        shadowView.backgroundColor = self.shadowViewColor
        
        shadowView.alpha = prevAlpha
        self.view.addSubview(shadowView)
        shadowView.pax_centerInSuperview()
        shadowView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideSideControllers))
        shadowView.addGestureRecognizer(tap)
        self.shadowView = shadowView
        if (self.mode != .onTop) {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            gesture.delegate = self
            shadowView.addGestureRecognizer(gesture)
        }
        else {
            if (self.mainViewController != nil){
                self.view.insertSubview(shadowView, aboveSubview:self.mainViewController!.view)
            }
        }
        
        
    }
    
    public func setMainViewController(_ mainViewController:UIViewController, animated:Bool = false) {
        let oldController = (mainViewController != self.mainViewController) ? self.mainViewController : nil
        
        let animated = oldController != nil ? animated : false
        self.mainViewController = mainViewController
        
        self.addChildViewController(mainViewController)
        if (self.shouldHideLeftViewControllerOnMainChange) {
            self.hideLeftViewController(animated: animated)
        }
        if (self.shouldHideRightViewControllerOnMainChange) {
            self.hideRightViewController(animated: animated)
        }
        switch self.mode {
        case .onTop:
            mainViewController.view.pax_centerInSuperview()
            if (oldController == nil) {
                self.view.insertSubview(mainViewController.view, at: 0)
            } else {
                self.view.insertSubview(mainViewController.view, aboveSubview: oldController!.view)
            }
        case .fixedLeft:
            
            if (self.leftViewController == nil) {
                self.view.insertSubview(mainViewController.view, at: 0)
            } else {
                self.view.insertSubview(mainViewController.view, aboveSubview:self.leftViewController!.view)
            }
            let oldValue = self.leftConstraint?.constant ?? 0.0
            self.leftConstraint = mainViewController.view.pax_alignLeft(width: self.view.frame.size.width)
            self.leftConstraint?.constant = oldValue
            
        case .fixedRight:
            
            if (self.rightViewController == nil) {
                self.view.insertSubview(mainViewController.view, at: 0)
            } else {
                self.view.insertSubview(mainViewController.view, aboveSubview:self.rightViewController!.view)
            }
            let oldValue = self.rightConstraint?.constant ?? 0.0
            self.rightConstraint = mainViewController.view.pax_alignRight(width: self.view.frame.size.width)
            self.rightConstraint?.constant = oldValue
        }
        
        let completion = {
            (finished:Bool) -> Void in
            oldController?.view.removeFromSuperview()
            oldController?.removeFromParentViewController()
        }
        if (animated && self.mode == .onTop) {
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
        if (self.mode == .fixedLeft) {
            if (self.shadowView?.superview == nil) {
                self.mainViewController?.view.addSubview(self.shadowView!)
                self.shadowView?.pax_centerInSuperview()
            }
            
        }
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
                if (self.mode == .fixedLeft) {
                    self.shadowView?.removeFromSuperview()
                }
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
        guard let rightViewController = self.rightViewController else {
            return
        }
        let view = rightViewController.view
        if (self.mode == .fixedRight) {
            if (self.shadowView?.superview == nil) {
                self.mainViewController?.view.addSubview(self.shadowView!)
                self.shadowView?.pax_centerInSuperview()
            }
            
        }
        guard let right = self.rightConstraint else {
            return
        }
        
        let shadowView = self.shadowView
        shadowView?.isHidden = false
        right.constant = self.rightOpenPosition
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
    func hideRightViewController(animated:Bool) {
        guard let rightViewController = self.rightViewController else {
            return
        }
        
        let view = rightViewController.view
        
        guard let right = self.rightConstraint else {
            return
        }
        
        guard let shadowView = self.shadowView else {
            return
        }
        right.constant = self.rightClosedPosition
        
        let animations = {
            view?.superview?.layoutIfNeeded()
            shadowView.alpha = 0
        }
        let completion = { (finished:Bool) -> Void in
            view?.setNeedsUpdateConstraints()
            view?.updateConstraintsIfNeeded()
            if (finished == true) {
                shadowView.isHidden = true
                if (self.mode == .fixedRight) {
                    self.shadowView?.removeFromSuperview()
                }
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
    
    fileprivate var panningPadding:CGFloat = 0.0
    
    func handlePan(_ panGesture:UIPanGestureRecognizer) {
        let velocity = panGesture.velocity(in: panGesture.view).x
        let edge = panGesture as? UIScreenEdgePanGestureRecognizer
        let isLeft = (panningView != nil && panningView == self.leftViewController?.view) || edge?.edges == UIRectEdge.left
        switch panGesture.state {
        case .began:
            if (self.isLeftOpen == false && self.isRightOpen == false) {
                panningView = isLeft ? self.leftViewController?.view : self.rightViewController?.view
                self.shadowView?.isHidden = false
                self.shadowView?.alpha = 0
            }
            else {
                panningView = isLeftOpen ? self.leftViewController?.view : self.rightViewController?.view
            }
            panningPadding = self.panningView?.frame.origin.x ?? 0.0;
            if (self.mode != .onTop) {
                
                self.shadowView?.removeFromSuperview()
                self.mainViewController?.view.addSubview(self.shadowView!)
                self.shadowView?.pax_centerInSuperview()
                if (isLeft){
                    panningPadding = panningPadding + (self.leftConstraint?.constant ?? 0.0)
                }
                else {
                    panningPadding = -(( panningPadding) + (self.rightConstraint?.constant ?? 0.0) - (self.view.frame.size.width - (self.rightViewController?.pax_width ?? 0)))
                }
            }
            else {
                setupShadowView()
            }
        case .ended:
            guard let _ = self.panningView else {
                return
            }
            if (velocity > self.view.frame.size.width / 3.0) {
                if (isLeft == true && self.isRightOpen == false) {
                    self.showLeftViewController(animated: true)
                }
                else {
                    
                    self.hideRightViewController(animated: true)
                }
            } else if (velocity < self.view.frame.size.width / 3.0) {
                if (self.isLeftOpen == false && isLeft == false) {
                    self.showRightViewController(animated: true)
                }
                else {
                    self.hideLeftViewController(animated: true)
                }
            }
            else {
                if (isLeft == true) {
                    let x = self.leftViewController?.view.frame.origin.x ?? 0.0
                    let w = self.leftViewController?.pax_width ??  0.0
                    let pos:CGFloat = (x - self.leftOpenPosition)/(w - self.leftOpenPosition)
                    abs(pos) > 0.5 ? self.hideLeftViewController(animated: true) : self.showLeftViewController(animated: true)
                }
                else {
                    let x = self.rightViewController?.view.frame.origin.x ?? 0.0
                    //                    let w = self.rightViewController?.pax_width ??  0.0
                    let pos:CGFloat = (x - self.rightOpenPosition)/(self.rightClosedPosition - self.rightOpenPosition)
                    abs(pos) > 0.5 ? self.hideRightViewController(animated: true) : self.showRightViewController(animated: true)
                }
            }
        case .changed:
            guard let _ = self.panningView else {
                return
            }
            var x = panGesture.translation(in: self.view).x
            
            //let closedNW = isLeft ? self.leftClosedPosition : self.rightClosedPosition
            //let openNW = isLeft ? self.leftOpenPosition : self.rightOpenPosition
            var alpha:CGFloat = 0.0
            if (isLeft) {
                x = max(self.leftClosedPosition, min(x + self.panningPadding , self.leftOpenPosition))
                alpha = shadowViewAlpha * (self.leftClosedPosition - x) / (self.leftClosedPosition - self.leftOpenPosition)
                
                self.leftConstraint?.constant = x
            }
            else {
                print ("Before: " + String(describing:x))
//                if (panGesture.view == self.rightViewController?.view) {
//                    x =   (self.rightOpenPosition) - x
//                    
//                }
//                print ("After: " + String(describing:x))
                //x = max(openNW, min(x +  self.panningPadding , closedNW))
                //alpha = self.shadowViewAlpha - abs(self.shadowViewAlpha * (x - openNW) / (openNW - closedNW))
                
                x = max(self.rightClosedPosition, (min(-(x + self.panningPadding) , self.rightOpenPosition)))
                alpha = shadowViewAlpha * (self.rightClosedPosition - x) / (self.rightClosedPosition - self.rightOpenPosition)
                print ("Setting: " + String(describing:x))
                self.rightConstraint?.constant = x//-max(self.view.frame.size.width - self.rightClosedPosition, min(self.view.frame.size.width - self.rightOpenPosition, self.view.frame.size.width - x))
            }
            print ("Alpha: " + String(describing:alpha))
            self.shadowView?.alpha = alpha
        default:
            print (panGesture.state)
            self.panningView = nil
            
        }
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        if (pan == self.rightPanGestureRecognizer && self.rightViewController == nil && self.isLeftOpen == false) {
            return false
        }
        if (pan == self.leftPanGestureRecognizer && self.leftViewController == nil && !self.isRightOpen == false) {
            return false
        }
        let velocity = pan.velocity(in: pan.view)
        return fabs(velocity.y) < fabs(velocity.x)
    }
}
