
import UIKit

public extension UIViewController {
    var pax: PaxProxy<UIViewController> {
        return PaxProxy(base: self)
    }
}

public struct PaxProxy<T: UIViewController> {
    var base: T

    init(base: T) {
        self.base = base
    }

    public var controller: Pax? {
        base as? Pax ?? base.parent?.pax.controller
    }

    public var menuWidth: CGFloat {
        get { base.pax_width }
        nonmutating set { base.pax_width = newValue}
    }

    public var mainEffect: MainEffect? {
        get { base.pax_mainEffect }
        nonmutating set { base.pax_mainEffect = newValue}
    }

    public func showLeft(animated: Bool = true) {
        controller?.showLeftViewController(animated: animated)
    }
    public func showRight(animated: Bool = true) {
        controller?.showRightViewController(animated: animated)
    }
}

fileprivate struct AssociatedKeys {
    static var Width = "pax_width"
    static var MainEffect = "pax_mainEffect"
}

public typealias MainEffect = (_ offset: CGFloat, _ viewController: UIViewController) -> Void

extension UIViewController {
    fileprivate var pax_width: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.Width) as? CGFloat ?? 0.0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.Width, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    fileprivate var pax_mainEffect: MainEffect? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.MainEffect) as? MainEffect
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.MainEffect, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

fileprivate extension UIView {

    func pax_centerInSuperview() {
        guard let container = self.superview else {
            return
        }

        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: container.topAnchor, constant: 0).isActive = true
        self.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0).isActive = true
        self.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0).isActive = true
        self.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0).isActive = true
    }
    func pax_mainControllerAndLeftMenu(leftView: UIView) {
        guard let container = self.superview else {
            return
        }

        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: container.topAnchor, constant: 0).isActive = true
        self.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0).isActive = true
        self.leadingAnchor.constraint(equalTo: leftView.trailingAnchor, constant: 0).isActive = true
        self.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
    }

    func pax_alignLeft(width: CGFloat) -> NSLayoutConstraint? {
        guard let container = self.superview else {
            return nil
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: container.topAnchor, constant: 0).isActive = true
        self.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0).isActive = true
        let left = self.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0)
        left.isActive = true
        self.widthAnchor.constraint(equalToConstant: width).isActive = true

        return left
    }
    func pax_alignRight(width: CGFloat) -> NSLayoutConstraint? {
        guard let container = self.superview else {
            return nil
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: container.topAnchor, constant: 0).isActive = true
        self.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0).isActive = true
        let right = container.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0)
        right.isActive = true
        self.widthAnchor.constraint(equalToConstant: width).isActive = true

        return right
    }
}

open class Pax: UIViewController, UIGestureRecognizerDelegate {

    private var shadowView: UIView?
    private var velocity: CGFloat = 0.0

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return mainViewController?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }

    var leftPanGestureRecognizer: UIPanGestureRecognizer?
    var rightPanGestureRecognizer: UIPanGestureRecognizer?

    public lazy var defaultEffect: MainEffect = { offset, viewController in
        let scale: CGFloat = 1.0 - (offset / 6.0)
        let radius: CGFloat = 20.0
        viewController.view.layer.cornerRadius = offset * radius
        viewController.view.layer.zPosition = 0
        var transform = CATransform3DMakeScale(scale, scale, 1)
        transform.m34 = -1 / 2000
        if scale == 1 {
            transform = CATransform3DIdentity
        }
        viewController.view.layer.transform = transform
    }
    lazy var leftEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let pan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.edges = .left
        pan.cancelsTouchesInView = true
        pan.delegate = self
        return pan
    }()

    lazy var rightEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let pan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.edges = .right
        pan.cancelsTouchesInView = true
        pan.delegate = self
        return pan
    }()

    private var _sideAnimationDuration: CGFloat = 0.2
    var sideAnimationDuration: CGFloat {
        get {
            return _sideAnimationDuration
        }
        set {
            _sideAnimationDuration = max(0.2, newValue)
        }
    }

    private var _mainAnimationDuration: CGFloat = 0.2
    var mainAnimationDuration: CGFloat {
        get {
            return _mainAnimationDuration
        }
        set {
            _mainAnimationDuration = max(0.2, newValue)
        }
    }

    private var leftOpenPosition: CGFloat = 0.0
    private var leftClosedPosition: CGFloat = 0.0

    private var rightOpenPosition: CGFloat = 0.0
    private var rightClosedPosition: CGFloat = 0.0

    private var leftConstraint: NSLayoutConstraint?
    private var leftMainConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?

    var shadowViewAlpha: CGFloat = 0.5 {
        didSet {
            self.shadowView?.alpha = shadowViewAlpha
        }
    }
    var shadowViewColor = UIColor.black {
        didSet {
            self.shadowView?.backgroundColor = shadowViewColor
        }
    }

    var leftParallaxAmount: CGFloat = 0.0
    var rightParallaxAmount: CGFloat = 0.0

    var shouldHideLeftViewControllerOnMainChange = true
    var shouldHideRightViewControllerOnMainChange = true

    var isLeftOpen: Bool {
        guard let left = self.leftViewController else {
            return false
        }
        return abs(left.view.frame.origin.x - self.leftClosedPosition) > 1
    }
    var isRightOpen: Bool {
        guard let right = self.rightViewController else {
            return false
        }
        return abs (right.view.frame.origin.x - self.view.bounds.width) > 1
    }

    fileprivate var panningView: UIView?

    var mainViewController: UIViewController?

    public var leftViewController: UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()
            guard let leftViewController = leftViewController else {
                return
            }
            _ = leftViewController.view
            let w = leftViewController.pax_width

            self.addChild(leftViewController)

            self.leftOpenPosition = 0
            self.leftClosedPosition = -w
            self.view.addSubview(leftViewController.view)
            self.leftConstraint = leftViewController.view.pax_alignLeft(width: w)

            self.hideLeftViewController(animated: false)
            leftViewController.view.isUserInteractionEnabled = true
            leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            leftPanGestureRecognizer?.cancelsTouchesInView = true
            leftViewController.view.addGestureRecognizer(leftPanGestureRecognizer ?? UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
            self.leftEdgePanGestureRecognizer.isEnabled = true
        }
    }

    public var rightViewController: UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()
            guard let rightViewController = rightViewController else {
                return
            }
            _ = rightViewController.view
            let w = rightViewController.pax_width

            self.addChild(rightViewController)

            self.rightOpenPosition = 0
            self.rightClosedPosition = -rightViewController.pax_width
            self.view.addSubview(rightViewController.view)
            self.rightConstraint = rightViewController.view.pax_alignRight(width: w)

            self.hideRightViewController(animated: false)
            rightViewController.view.isUserInteractionEnabled = true
            rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            rightViewController.view.addGestureRecognizer(rightPanGestureRecognizer ?? UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
            self.rightEdgePanGestureRecognizer.isEnabled = true
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupShadowView()
        view.backgroundColor = .darkGray
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

        shadowView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideSideControllers))
        shadowView.addGestureRecognizer(tap)
        self.shadowView = shadowView

        if (self.mainViewController != nil) {

            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            gesture.delegate = self
            shadowView.addGestureRecognizer(gesture)

            self.view.insertSubview(shadowView, aboveSubview: self.mainViewController!.view)
            shadowView.pax_centerInSuperview()

        }

    }

    public func setMainViewController(_ mainViewController: UIViewController, animated: Bool = false) {
        let oldController = (mainViewController != self.mainViewController) ? self.mainViewController : nil

        let animated = oldController != nil ? animated : false
        self.mainViewController = mainViewController

        self.addChild(mainViewController)
        self.updateMainAnimation((self.isLeftOpen || self.isRightOpen) ? 1 : 0)
        if (self.shouldHideLeftViewControllerOnMainChange) {
            self.hideLeftViewController(animated: animated)
        }
        else if (self.shouldHideRightViewControllerOnMainChange) {
            self.hideRightViewController(animated: animated)
        }
        if (oldController == nil) {
            self.view.insertSubview(mainViewController.view, at: 0)
        } else {
            self.view.insertSubview(mainViewController.view, aboveSubview: oldController!.view)
        }
        if let left = leftViewController?.view {
            mainViewController.view.pax_centerInSuperview()
        } else {
            mainViewController.view.pax_centerInSuperview()
        }
        self.setupShadowView()

        let completion = { [weak self]
            (finished: Bool) -> Void in
            oldController?.view.removeFromSuperview()
            oldController?.removeFromParent()

        }
        if animated {
//            mainViewController.view.alpha = 0
            UIView.animate(withDuration: TimeInterval(self.mainAnimationDuration), animations: {
                mainViewController.view.alpha = 1
            }, completion: completion)
        } else {
            completion(true)
        }
        mainViewController.view.addGestureRecognizer(self.leftEdgePanGestureRecognizer)
        mainViewController.view.addGestureRecognizer(self.rightEdgePanGestureRecognizer)
        mainViewController.view.layer.masksToBounds = true
        
    }

    @objc func hideSideControllers() {

        if (self.isLeftOpen) {
            self.hideLeftViewController(animated: true)
        }
        if (self.isRightOpen) {
            self.hideRightViewController(animated: true)
        }
    }
    
    public func updateMainAnimation(_ offset: CGFloat) {
        if let viewController = self.mainViewController {
            (viewController.pax.mainEffect ?? self.defaultEffect)(offset, viewController)
        }
    }
    
    public func showLeftViewController(animated: Bool) {
        guard let leftViewController = self.leftViewController else {
            return
        }

        let view = leftViewController.view
        guard let left = self.leftConstraint else {
            return
        }

        let shadowView = self.shadowView
        shadowView?.isHidden = false
        leftViewController.view.layer.zPosition = 1
        left.constant = self.leftOpenPosition
        let shadowViewAlpha = self.shadowViewAlpha

        let animations = {
            view?.superview?.layoutIfNeeded()
            shadowView?.alpha = shadowViewAlpha
            let relative: CGFloat = 1.0
            self.updateMainAnimation(relative)
        }
        let completion = { (finished: Bool) -> Void in
            return
        }

        if (animated) {
            UIView.animate(withDuration: currentAnimationDuration,
                           delay: 0, options: .curveEaseOut,
                           animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }

    }
    public func hideLeftViewController(animated: Bool, completion: @escaping (Bool)->Void = { _ in }) {
        guard self.leftViewController != nil else {
            completion(false)
            return
        }
        leftEdgePanGestureRecognizer.isEnabled = false
        rightEdgePanGestureRecognizer.isEnabled = false
        rightPanGestureRecognizer?.isEnabled = false
        leftPanGestureRecognizer?.isEnabled = false

        self.leftConstraint?.constant = self.leftClosedPosition

        let animations = { [weak self] in
            self?.leftViewController?.view?.superview?.layoutIfNeeded()
            self?.shadowView?.alpha = 0
            self?.updateMainAnimation(0)
        }
        let ending = { [weak self] (finished: Bool) -> Void in
            self?.leftEdgePanGestureRecognizer.isEnabled = true
            self?.rightPanGestureRecognizer?.isEnabled = true
            self?.leftPanGestureRecognizer?.isEnabled = true
            self?.rightEdgePanGestureRecognizer.isEnabled = true
            self?.leftViewController?.view?.setNeedsUpdateConstraints()
            self?.leftViewController?.view?.updateConstraintsIfNeeded()
            self?.panningView = nil
            if (finished == true) {
                self?.shadowView?.isHidden = true
            }
            completion(finished)
        }

        if (animated) {
            UIView.animate(withDuration: currentAnimationDuration,
                           delay: 0, options: .curveEaseOut,
                           animations: animations, completion: ending)
        } else {
            animations()
            ending(true)
        }
    }
    var currentAnimationDuration: TimeInterval {
        velocity = 1
        return TimeInterval(sideAnimationDuration / (max(1, velocity)))
    }
    public func showRightViewController(animated: Bool) {
        guard let leftViewController = self.rightViewController else {
            return
        }

        let view = leftViewController.view
        guard let left = self.rightConstraint else {
            return
        }

        let shadowView = self.shadowView
        shadowView?.isHidden = false
        leftViewController.view.layer.zPosition = 1
        left.constant = self.rightOpenPosition
        let shadowViewAlpha = self.shadowViewAlpha

        let animations = {
            view?.superview?.layoutIfNeeded()
            shadowView?.alpha = shadowViewAlpha
            let relative: CGFloat = 1.0
            self.updateMainAnimation(relative)
        }
        let completion = { (finished: Bool) -> Void in
            return
        }

        if (animated) {
            UIView.animate(withDuration: currentAnimationDuration,
                           delay: 0, options: .curveEaseOut,
                           animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }

    }
    public func hideRightViewController(animated: Bool, completion: @escaping (Bool)->Void = { _ in }) {
        guard self.rightViewController != nil else {
            completion(false)
            return
        }
        leftEdgePanGestureRecognizer.isEnabled = false
        rightEdgePanGestureRecognizer.isEnabled = false
        rightPanGestureRecognizer?.isEnabled = false
        leftPanGestureRecognizer?.isEnabled = false

        self.rightConstraint?.constant = self.rightClosedPosition

        let animations = { [weak self] in
            self?.rightViewController?.view?.superview?.layoutIfNeeded()
            self?.shadowView?.alpha = 0
            self?.updateMainAnimation(0)
        }
        let ending = { [weak self] (finished: Bool) -> Void in
            self?.leftEdgePanGestureRecognizer.isEnabled = true
            self?.rightPanGestureRecognizer?.isEnabled = true
            self?.leftPanGestureRecognizer?.isEnabled = true
            self?.rightEdgePanGestureRecognizer.isEnabled = true
            self?.rightViewController?.view?.setNeedsUpdateConstraints()
            self?.rightViewController?.view?.updateConstraintsIfNeeded()
            self?.panningView = nil
            if (finished == true) {
                self?.shadowView?.isHidden = true
            }
            completion(finished)
        }

        if (animated) {
            UIView.animate(withDuration: currentAnimationDuration,
                           delay: 0, options: .curveEaseOut,
                           animations: animations, completion: ending)
        } else {
            animations()
            ending(true)
        }
    }

    fileprivate var panningPadding: CGFloat = 0.0

    @objc func handlePan(_ panGesture: UIPanGestureRecognizer) {
        let velocity = panGesture.velocity(in: panGesture.view).x

        let edge = panGesture as? UIScreenEdgePanGestureRecognizer
        let isLeft = (panningView != nil && panningView == self.leftViewController?.view) || edge?.edges == UIRectEdge.left
        switch panGesture.state {
        case .began:
            self.velocity = 0
            if (self.isLeftOpen == false && self.isRightOpen == false) {
                panningView = isLeft ? self.leftViewController?.view : self.rightViewController?.view
                self.shadowView?.isHidden = false
                self.shadowView?.alpha = 0
            } else {
                panningView = isLeftOpen ? self.leftViewController?.view : self.rightViewController?.view
            }
            if !isLeft {
                panningPadding = self.panningView?.frame.minX ?? 0.0
            } else {
                panningPadding = self.panningView?.frame.origin.x ?? 0.0
            }
        case .ended:
            guard self.panningView != nil else {
                return
            }

            if (velocity > self.view.frame.size.width / 4.0 && isLeft == true && self.isRightOpen == false) {

                self.showLeftViewController(animated: true)

            } else if (velocity < self.view.frame.size.width / 4.0 && self.isLeftOpen == false && isLeft == false) {

                self.showRightViewController(animated: true)

            } else {
                if (isLeft == true) {

                    let w = self.leftViewController?.pax_width ??  0.0
                    var hide: Bool = false

                    let x = self.leftViewController?.view.frame.origin.x ?? 0.0
                    let pos: CGFloat = (x - self.leftOpenPosition)/(w - self.leftOpenPosition)
                    hide = abs(pos * min(1, velocity)) > 0.5


                    hide ? self.hideLeftViewController(animated: true) : self.showLeftViewController(animated: true)

                } else {
                    let x = self.rightViewController?.view.frame.origin.x ?? 0.0
                    //                    let w = self.rightViewController?.pax_width ??  0.0
                    let pos: CGFloat = (x - self.rightOpenPosition)/(self.rightClosedPosition - self.rightOpenPosition)
                    abs(pos) > 0.5 ? self.hideRightViewController(animated: true) : self.showRightViewController(animated: true)
                }
            }
        case .changed:
            guard self.panningView != nil else {
                return
            }
            var x = panGesture.translation(in: self.view).x
            self.velocity = velocity

            var alpha: CGFloat = 0.0
            if (isLeft) {
                x = max(self.leftClosedPosition, min(x + self.panningPadding, self.leftOpenPosition))
                alpha = shadowViewAlpha * (self.leftClosedPosition - x) / (self.leftClosedPosition - self.leftOpenPosition)

                self.leftConstraint?.constant = x
            } else {
                let delta = view.bounds.width - (rightViewController?.pax_width ?? 0)
                x = max(self.rightClosedPosition, (min(-(x + self.panningPadding - delta), self.rightOpenPosition)))
                alpha = shadowViewAlpha * (self.rightClosedPosition - x) / (self.rightClosedPosition - self.rightOpenPosition)
                self.rightConstraint?.constant = x
            }
            self.shadowView?.alpha = alpha

            let relative = (alpha / shadowViewAlpha)
            self.updateMainAnimation(relative)

        default:
            self.panningView = nil
        }
    }



    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        if (pan == self.rightEdgePanGestureRecognizer && self.rightViewController == nil && self.isLeftOpen == false) {
            return false
        }
        if (pan == self.leftEdgePanGestureRecognizer && self.leftViewController == nil && !self.isRightOpen == false) {
            return false
        }
        let velocity = pan.velocity(in: pan.view)
        return abs(velocity.y) < abs(velocity.x)
    }
}

