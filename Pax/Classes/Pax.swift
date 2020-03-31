// swiftlint:disable file_length

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
        get { base.paxWidth }
        nonmutating set { base.paxWidth = newValue}
    }

    public var mainEffect: MainEffect? {
        get { base.mainEffect }
        nonmutating set { base.mainEffect = newValue}
    }
    public func showMenu(at side: Pax.Side, animated: Bool = true) {
        controller?.showViewController(at: side, animated: animated)
    }
}

private struct AssociatedKeys {
    static var Width = "pax_width"
    static var MainEffect = "pax_mainEffect"
}

public typealias MainEffect = (_ offset: CGFloat, _ viewController: UIViewController) -> Void

extension UIViewController {
    fileprivate var paxWidth: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.Width) as? CGFloat ?? 0.0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.Width, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    fileprivate var mainEffect: MainEffect? {
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

open class Pax: UIViewController {

    public enum Side: CaseIterable {
        case left
        case right
    }
    private var shadowView: UIView?
    private var velocity: CGFloat = 0.0

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return mainViewController?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }

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

    public var mainAnimationDuration: CGFloat {
        get {
            return _mainAnimationDuration
        }
        set {
            _mainAnimationDuration = max(0.2, newValue)
        }
    }

    private var panningView: UIView?
    private var sideControllers: [Side: UIViewController] = [:]
    private var _mainAnimationDuration: CGFloat = 0.2
    private var leftOpenPosition: CGFloat = 0.0
    private var leftClosedPosition: CGFloat = 0.0

    private var rightOpenPosition: CGFloat = 0.0
    private var rightClosedPosition: CGFloat = 0.0

    private var leftConstraint: NSLayoutConstraint?
    private var leftMainConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?

    private var leftPanGestureRecognizer: UIPanGestureRecognizer?
    private var rightPanGestureRecognizer: UIPanGestureRecognizer?

    private var panningPadding: CGFloat = 0.0

    public var shadowViewAlpha: CGFloat = 0.5 {
        didSet {
            self.shadowView?.alpha = shadowViewAlpha
        }
    }
    public var shadowViewColor = UIColor.black {
        didSet {
            self.shadowView?.backgroundColor = shadowViewColor
        }
    }

    public var hidesLeftViewControllerOnMainChange = true
    public var hidesRightViewControllerOnMainChange = true

    open func viewController(at side: Side) -> UIViewController? {
        return sideControllers[side]
    }

    var mainViewController: UIViewController?

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupShadowView()
        view.backgroundColor = .darkGray
    }

    @objc func hideSideControllers() {
        Side.allCases
            .filter { self.isOpen(at: $0)}
            .forEach { self.hideViewController(at: $0, animated: true) }
    }

    public func updateMainAnimation(_ offset: CGFloat) {
        if let viewController = self.mainViewController {
            (viewController.pax.mainEffect ?? self.defaultEffect)(offset, viewController)
        }
    }

    var currentAnimationDuration: TimeInterval {
        //        velocity = 1
        //        return TimeInterval(sideAnimationDuration / (max(1, velocity)))
        return TimeInterval(sideAnimationDuration)
    }

    @objc func handlePan(_ panGesture: UIPanGestureRecognizer) {
        let velocity = panGesture.velocity(in: panGesture.view).x
        let edge = panGesture as? UIScreenEdgePanGestureRecognizer
        let side: Side = ((panningView != nil && panningView == viewController(at: .left)?.view) ||
            edge?.edges == UIRectEdge.left) ? .left : .right

        switch panGesture.state {
        case .began:
            self.handlePanBegin(for: panGesture, side: side)
        case .ended:
            self.handlePanEnd(for: panGesture, side: side, velocity: velocity)
        case .changed:
            handlePanChanged(for: panGesture, side: side, velocity: velocity)

        default:
            self.panningView = nil
        }
    }
}

extension Pax: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        if pan == self.rightEdgePanGestureRecognizer &&
            self.viewController(at: .right) == nil &&
            self.isOpen(at: .left) == false {
            return false
        }
        if pan == self.leftEdgePanGestureRecognizer &&
            self.viewController(at: .left) == nil &&
            !self.isOpen(at: .right) == false {
            return false
        }
        let velocity = pan.velocity(in: pan.view)
        return abs(velocity.y) < abs(velocity.x)
    }
}

extension Pax {

    public func setMainViewController(_ mainViewController: UIViewController, animated: Bool = false) {
        let oldController = (mainViewController != self.mainViewController) ? self.mainViewController : nil

        let animated = oldController != nil ? animated : false
        self.mainViewController = mainViewController

        self.addChild(mainViewController)
        self.updateMainAnimation((self.isOpen(at: .left) || self.isOpen(at: .right)) ? 1 : 0)
        if hidesLeftViewControllerOnMainChange {
            self.hideViewController(at: .left, animated: animated)
        } else if hidesRightViewControllerOnMainChange {
            self.hideViewController(at: .right, animated: animated)
        }
        if oldController == nil {
            self.view.insertSubview(mainViewController.view, at: 0)
        } else {
            self.view.insertSubview(mainViewController.view, aboveSubview: oldController!.view)
        }

        mainViewController.view.pax_centerInSuperview()

        self.setupShadowView()

        let completion = {(finished: Bool) -> Void in
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

    public func isOpen(at side: Side) -> Bool {
        guard let viewController = self.viewController(at: side) else {
            return false
        }
        switch side {
        case .left: return abs(viewController.view.frame.origin.x - self.leftClosedPosition) > 1
        case .right: return abs(viewController.view.frame.origin.x - self.view.bounds.width) > 1
        }
    }

    open func setViewController(_ viewController: UIViewController?, at side: Side) {
        let oldViewController = self.viewController(at: side)
        oldViewController?.view.removeFromSuperview()
        oldViewController?.removeFromParent()
        guard let viewController = viewController else {
            sideControllers[side] = nil
            return
        }
        sideControllers[side] = viewController
        _ = viewController.view
        self.addChild(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.isUserInteractionEnabled = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gesture.cancelsTouchesInView = true
        viewController.view.addGestureRecognizer(gesture)
        let menuWidth = viewController.pax.menuWidth
        switch side {
        case .left:
            self.leftOpenPosition = 0
            self.leftClosedPosition = -menuWidth
            self.leftConstraint = viewController.view.pax_alignLeft(width: menuWidth)
            self.leftPanGestureRecognizer = gesture
            self.leftEdgePanGestureRecognizer.isEnabled = true
        case .right:
            self.rightOpenPosition = 0
            self.rightClosedPosition = -menuWidth
            self.rightConstraint = viewController.view.pax_alignRight(width: menuWidth)
            self.rightPanGestureRecognizer = gesture
            self.rightEdgePanGestureRecognizer.isEnabled = true

        }
        self.hideViewController(at: side, animated: false)
    }

    public func showViewController(at side: Side, animated: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let viewController = self.viewController(at: side) else { return }
        let view = viewController.view
        let shadowView = self.shadowView
        shadowView?.isHidden = false
        viewController.view.layer.zPosition = 1
        let shadowViewAlpha = self.shadowViewAlpha

        switch side {
        case .left:
            guard let constraint = leftConstraint else { return }
            constraint.constant = self.leftOpenPosition
        case .right:
            guard let constraint = rightConstraint else { return }
            constraint.constant = self.rightOpenPosition
        }

        let animations = {
            view?.superview?.layoutIfNeeded()
            shadowView?.alpha = shadowViewAlpha
            let relative: CGFloat = 1.0
            self.updateMainAnimation(relative)
        }
        if animated {
            UIView.animate(withDuration: currentAnimationDuration,
                           delay: 0, options: .curveEaseOut,
                           animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }
    public func hideViewController(at side: Side, animated: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let viewController = self.viewController(at: side) else { return }
        leftEdgePanGestureRecognizer.isEnabled = false
        rightEdgePanGestureRecognizer.isEnabled = false
        rightPanGestureRecognizer?.isEnabled = false
        leftPanGestureRecognizer?.isEnabled = false
        switch side {
        case .left: self.leftConstraint?.constant = self.leftClosedPosition
        case .right: self.rightConstraint?.constant = self.rightClosedPosition
        }
        let animations = { [weak self] in
            viewController.view?.superview?.layoutIfNeeded()
            self?.shadowView?.alpha = 0
            self?.updateMainAnimation(0)
        }
        let ending = { [weak self] (finished: Bool) -> Void in
            self?.leftEdgePanGestureRecognizer.isEnabled = true
            self?.rightPanGestureRecognizer?.isEnabled = true
            self?.leftPanGestureRecognizer?.isEnabled = true
            self?.rightEdgePanGestureRecognizer.isEnabled = true
            viewController.view?.setNeedsUpdateConstraints()
            viewController.view?.updateConstraintsIfNeeded()
            self?.panningView = nil
            if finished {
                self?.shadowView?.isHidden = true
            }
            completion(finished)
        }

        if animated {
            UIView.animate(withDuration: currentAnimationDuration,
                           delay: 0,
                           options: .curveEaseOut,
                           animations: animations,
                           completion: ending)
        } else {
            animations()
            ending(true)
        }
    }
}

fileprivate extension Pax {
    func setupShadowView() {
        if self.isViewLoaded == false {
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

        if self.mainViewController != nil {

            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            gesture.delegate = self
            shadowView.addGestureRecognizer(gesture)

            self.view.insertSubview(shadowView, aboveSubview: self.mainViewController!.view)
            shadowView.pax_centerInSuperview()

        }

    }
}
fileprivate extension Pax {
     func handlePanBegin(for panGesture: UIPanGestureRecognizer, side: Side) {
        self.velocity = 0
        if isOpen(at: .left) == false && isOpen(at: .right) == false {
            panningView = self.viewController(at: side)?.view
            self.shadowView?.isHidden = false
            self.shadowView?.alpha = 0
        } else {
            panningView = (isOpen(at: .left) ?
                viewController(at: .left) :
                viewController(at: .right))?.view
        }
        panningPadding = self.panningView?.frame.minX ?? 0.0
    }
    func handlePanEnd(for panGesture: UIPanGestureRecognizer, side: Side, velocity: CGFloat) {
        guard self.panningView != nil else {
            return
        }

        if velocity > view.frame.size.width / 4.0 && side == .left && isOpen(at: .right) == false {
            showViewController(at: .left, animated: true)

        } else if velocity < view.frame.size.width / 4.0 && isOpen(at: .left) == false && side == .right {

            showViewController(at: .right, animated: true)

        } else {
            guard let viewController = self.viewController(at: side) else { return }
            var hide: Bool = false
            let minX = viewController.view.frame.minX
            switch side {
            case .left:

                let position = (minX - self.leftOpenPosition)/(viewController.pax.menuWidth - self.leftOpenPosition)
                hide = abs(position * min(1, velocity)) > 0.5
            case .right:
                let position: CGFloat = (minX - rightOpenPosition)/(rightClosedPosition - rightOpenPosition)
                hide = abs(position) > 0.5
            }
            hide ?
                self.hideViewController(at: side, animated: true) :
                self.showViewController(at: side, animated: true)

        }
    }

    func handlePanChanged(for panGesture: UIPanGestureRecognizer, side: Side, velocity: CGFloat) {
        guard self.panningView != nil else {
            return
        }
        var origin = panGesture.translation(in: self.view).x
        self.velocity = velocity

        var alpha: CGFloat = 0.0
        switch side {
        case .left:
            origin = max(self.leftClosedPosition, min(origin + self.panningPadding, self.leftOpenPosition))
            alpha = shadowViewAlpha * (leftClosedPosition - origin) / (leftClosedPosition - leftOpenPosition)
            self.leftConstraint?.constant = origin
        case .right:
            let delta = view.bounds.width - (viewController(at: .right)?.paxWidth ?? 0)
            origin = max(rightClosedPosition, (min(-(origin + self.panningPadding - delta), rightOpenPosition)))
            alpha = shadowViewAlpha * (rightClosedPosition - origin) / (rightClosedPosition - rightOpenPosition)
            self.rightConstraint?.constant = origin
        }
        self.shadowView?.alpha = alpha

        let relative = (alpha / shadowViewAlpha)
        self.updateMainAnimation(relative)
    }
}
