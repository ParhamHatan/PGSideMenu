    //
//  DoorMenuViewController.swift
//  SwiftDemos
//
//  Created by Piotr Gorzelany on 22/05/16.
//  Copyright © 2016 Piotr Gorzelany. All rights reserved.
//

import UIKit

private enum Side {
    
    case Left, Right
    
}
    
protocol PGSideMenuDelegate {
    
    func PGSideMenuDelegateWillShowLeftMenu(menu: PGSideMenu)
    func PGSideMenuDelegateWillShowRightMenu(menu: PGSideMenu)
    func PGSideMenuDelegateWillHideLeftMenu(menu: PGSideMenu)
    func PGSideMenuDelegateWillHideRightMenu(menu: PGSideMenu)
    
}

public class PGSideMenu: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var contentContainerView: UIView!
    @IBOutlet weak var leftMenuContainerView: UIView!
    @IBOutlet weak var rightMenuContainerView: UIView!
    
    @IBOutlet weak var contentViewCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftMenuWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightMenuWidthConstraint: NSLayoutConstraint!
    
    // MARK: Public Properties
    
    /** The width of the menu container as a percentage of the screen */
    public var menuWidth: CGFloat = 0.8
    
    /** The scale factor for the content view when menu is shown */
    public var contentScaleFactor: CGFloat = 0.9
    
    /** Duration of the menu opening animation */
    public var menuAnimationDuration: NSTimeInterval = 0.4
    
    public var menuAnimationOptions: UIViewAnimationOptions = .CurveEaseOut
    
    public var contentController: UIViewController?
    public var leftMenuController: UIViewController?
    public var rightMenuController: UIViewController?
    
    // MARK: Private properties
    
    private var maxAbsoluteContentTranslation: CGFloat {
        return UIScreen.mainScreen().bounds.width * self.menuWidth
    }
    
    /** The maximum angle (in degrees) the door menu can open */
    private let menuTilt: CGFloat = 45
    
    /** Content translation at the beggining of the pan gesture */
    private var initialContentTranslation: CGFloat = 0
    
    private var animating = false
    
    private var isLeftMenuShown: Bool {
        
        return self.contentViewCenterConstraint.constant == self.maxAbsoluteContentTranslation
        
    }
    
    private var isRightMenuShown: Bool {
        
        return self.contentViewCenterConstraint.constant == -self.maxAbsoluteContentTranslation
        
    }
    
    // MARK: Initializers
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init() {
        
        let podBundle = NSBundle(forClass: PGSideMenu.self)
        let bundleURL = podBundle.URLForResource("PGSideMenu", withExtension: "bundle")
        let bundle = NSBundle(URL: bundleURL!)!
        super.init(nibName: "PGSideMenu", bundle: bundle)
        let _ = self.view // used to set all outlets
        
    }
    
    // MARK: Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Door Menu"
        self.configureController()
        self.addShadowToContentView()
        
    }
    
    // MARK: Actions
    
    @IBAction func leftButtonTouched(sender: UIButton) {
        
        self.toggleLeftMenu()
        
    }
    
    @IBAction func rightButtonTouched(sender: UIButton) {
        
        self.toggleRightMenu()
        
    }
    
    // MARK: Support
    
    private func configureController(){
        
        self.leftMenuWidthConstraint.constant = self.maxAbsoluteContentTranslation
        self.rightMenuWidthConstraint.constant = self.maxAbsoluteContentTranslation
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized))
        self.view.addGestureRecognizer(panGestureRecognizer)
        
    }
    
    func panGestureRecognized(recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translationInView(self.view)
        
        switch recognizer.state {
            
        case .Began:
            
            self.initialContentTranslation = self.contentViewCenterConstraint.constant
            
        case .Changed:
            
            self.translateContentView(inXDimension: translation.x + self.initialContentTranslation)
            
        case .Ended:
            
            self.handlePanGestureEnd()
            
        default:
            
            break
            
        }
        
    }
    
    /** The absolute translation to make on the content view */
    private func translateContentView(inXDimension x: CGFloat, animated: Bool = false) {

        // Do not translate if the translation is at the maximum
        guard abs(x) <= self.maxAbsoluteContentTranslation else {return}
        
        // Do not translate, if there is no menu
        if x > 0 && self.leftMenuController == nil {
            self.hideMenu(animated: false)
            return
        }
        
        if x < 0 && self.rightMenuController == nil {
            self.hideMenu(animated: false)
            return
        }
        
        let relativeTranslation = x / maxAbsoluteContentTranslation
        
        self.contentViewCenterConstraint.constant = x
        
        // 3d transforms
        
        let relative3dAngleTranslation: CGFloat = -(self.menuTilt * relativeTranslation)
        let contentContainerViewWidthAfterTranslation = self.contentContainerView.bounds.size.width * cos(Angle.degreesToRadians(degrees: relative3dAngleTranslation))
        var relative3dXTranslation: CGFloat =  self.contentContainerView.bounds.size.width - contentContainerViewWidthAfterTranslation
        relative3dXTranslation = x > 0 ? -relative3dXTranslation : relative3dXTranslation
        let relative3dScaleTranslation = 1 - (abs(relativeTranslation) * (1 - self.contentScaleFactor))
        
        var transform = CATransform3DIdentity;
        transform = CATransform3DScale(transform, 1, relative3dScaleTranslation, 1)
        transform.m34 = 1.0 / -1500;
        transform = CATransform3DRotate(transform, Angle.degreesToRadians(degrees: relative3dAngleTranslation), 0, 1, 0.0);
        transform = CATransform3DTranslate(transform, relative3dXTranslation, 0, 0)
        
        if animated {
            
            UIView.animateWithDuration(self.menuAnimationDuration, delay: 0, options: self.menuAnimationOptions, animations: {
                
                self.contentContainerView.layer.transform = transform;
                self.view.layoutSubviews()
                
                }, completion: nil)
            
        } else {
            
            self.contentContainerView.layer.transform = transform;
            
        }

    }
    
    private func handlePanGestureEnd() {
        
        if abs(self.contentViewCenterConstraint.constant) > self.maxAbsoluteContentTranslation / 2.0 {
            
            // Almost opened
            
            self.contentViewCenterConstraint.constant > 0 ? self.showMenu(.Left) : self.showMenu(.Right)
            
            
        } else {
            
            self.hideMenu()
            
        }
        
    }
    
    private func showMenu(side: Side) {
        
        let translation = side == .Left ? self.maxAbsoluteContentTranslation : -self.maxAbsoluteContentTranslation
        
        self.translateContentView(inXDimension: translation, animated: true)
        
    }
    
    private func hideMenu(animated animated: Bool = true) {
        
        self.contentViewCenterConstraint.constant = 0
        
        if animated {
            
            UIView.animateWithDuration(self.menuAnimationDuration, delay: 0, options: self.menuAnimationOptions, animations: {
                
                self.contentContainerView.layer.transform = CATransform3DIdentity
                self.view.layoutSubviews()
                
            }, completion: nil)
            
        } else {
            
            self.contentContainerView.layer.transform = CATransform3DIdentity
            self.view.layoutSubviews()
            
        }
        
    }
    
    private func toggleMenu(side: Side) {
        
        if self.isLeftMenuShown || self.isRightMenuShown {
            
            self.hideMenu()
            
        } else {
            
            self.showMenu(side)
        }
        
    }
    
    public func toggleLeftMenu() {
        
        self.toggleMenu(.Left)
        
    }
    
    public func toggleRightMenu() {
        
        self.toggleMenu(.Right)
    }
    
    public func addContentController(controller: UIViewController) {
        
        self.addChildViewController(controller)
        self.contentContainerView.addSubviewFullscreen(controller.view)
        self.contentController = controller
        controller.didMoveToParentViewController(self)
        
    }
    
    public func addLeftMenuController(controller: UIViewController) {
        
        self.addChildViewController(controller)
        self.leftMenuContainerView.addSubviewFullscreen(controller.view)
        self.leftMenuController = controller
        controller.didMoveToParentViewController(self)
        
    }
    
    public func addRightMenuController(controller: UIViewController) {
        
        
        self.addChildViewController(controller)
        self.rightMenuContainerView.addSubviewFullscreen(controller.view)
        self.rightMenuController = controller
        controller.didMoveToParentViewController(self)
    }
    
    // MARK: Appearance
    
    private func addShadowToContentView() {

        self.contentContainerView.layer.shadowColor = UIColor.blackColor().CGColor
        self.contentContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.contentContainerView.layer.shadowOpacity = 0.8
        self.contentContainerView.layer.masksToBounds = false
        
    }
}
