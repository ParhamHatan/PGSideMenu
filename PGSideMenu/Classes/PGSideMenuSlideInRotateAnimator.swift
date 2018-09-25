//
//  PGSideMenuSlideInRotateAnimator.swift
//  Pods
//
//  Created by Piotr Gorzelany on 11/09/16.
//
//

import Foundation

class PGSideMenuSlideInRotateAnimator {
    
    // MARK: Properties
    
    unowned let sideMenu: PGSideMenu
    
    var maxAbsoluteContentTranslation: CGFloat {
        return UIScreen.main.bounds.width * sideMenu.menuPercentWidth
    }
    
    let menuTilt: CGFloat = 45
    
    var initialContentTranslation: CGFloat = 0
    
    // MARK: Lifecycle
    
    required init(sideMenu: PGSideMenu) {
        self.sideMenu = sideMenu
        
        
        self.configureSideMenu()
    }
    
    // MARK: Methods
    
    func configureSideMenu() {
    
        self.sideMenu.rightMenuWidthConstraint.constant = self.maxAbsoluteContentTranslation
        self.addShadowToContentView()
    }
    
    func addShadowToContentView() {
        
        self.sideMenu.contentContainerView.layer.shadowColor = UIColor.black.cgColor
        self.sideMenu.contentContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.sideMenu.contentContainerView.layer.shadowOpacity = 0.8
        self.sideMenu.contentContainerView.layer.masksToBounds = false
    }
    
    func translateContentView(inXDimension x: CGFloat, animated: Bool) {
        
        // Do not translate if the translation is at the maximum
        guard abs(x) <= self.maxAbsoluteContentTranslation else {return}
        
        
        if x < 0 && self.sideMenu.rightMenuController == nil {
            self.hideMenu(animated: false)
            return
        }
        
        // Add overlay
        self.sideMenu.addContentOverlay()
        
        let relativeTranslation = x / maxAbsoluteContentTranslation
        
        self.sideMenu.contentViewCenterConstraint.constant = x
        
        // 3d transforms
        
        let relative3dAngleTranslation: CGFloat = -(self.menuTilt * relativeTranslation)
        let contentContainerViewWidthAfterTranslation = self.sideMenu.contentContainerView.bounds.size.width * cos(Angle.degreesToRadians(degrees: relative3dAngleTranslation))
        var relative3dXTranslation: CGFloat =  self.sideMenu.contentContainerView.bounds.size.width - contentContainerViewWidthAfterTranslation
        relative3dXTranslation = x > 0 ? -relative3dXTranslation : relative3dXTranslation
        let relative3dScaleTranslation = 1 - (abs(relativeTranslation) * (1 - self.sideMenu.contentScaleFactor))
        
        var transform = CATransform3DIdentity;
        transform = CATransform3DScale(transform, 1, relative3dScaleTranslation, 1)
        transform.m34 = 1.0 / -1500;
        transform = CATransform3DRotate(transform, Angle.degreesToRadians(degrees: relative3dAngleTranslation), 0, 1, 0.0);
        transform = CATransform3DTranslate(transform, relative3dXTranslation, 0, 0)
        
        if animated {
            
            UIView.animate(withDuration: self.sideMenu.menuAnimationDuration, delay: 0, options: self.sideMenu.menuAnimationOptions, animations: {
                
                self.sideMenu.contentContainerView.layer.transform = transform;
                self.sideMenu.view.layoutSubviews()
                
                }, completion: nil)
            
        } else {
            
            self.sideMenu.contentContainerView.layer.transform = transform;
            
        }

    }
    
}

// MARK: PGSideMenuAnimationDelegate

extension PGSideMenuSlideInRotateAnimator: PGSideMenuAnimationDelegate {
    
    func toggleMenu(side: Side) {
        
        if self.isRightMenuOpen {
            
            self.hideMenu()
            
        } else {
            
            self.openRightMenu()
            
        }
    }
    
    
    
    func toggleRightMenu(animated: Bool = true) {
        
        self.toggleMenu(side: .right)
    }
    
    func openRightMenu(animated: Bool = true) {
        
        self.translateContentView(inXDimension: -self.maxAbsoluteContentTranslation, animated: animated)
    }
    
    func closeRightMenu(animated: Bool = true) {
        
        self.hideMenu()
    }
    
    var isRightMenuOpen: Bool {
        
        return sideMenu.contentViewCenterConstraint.constant == -self.maxAbsoluteContentTranslation
    }
    
    func hideMenu(animated: Bool = true) {
        
        guard self.sideMenu.contentViewCenterConstraint.constant != 0 else {return}
        
        self.sideMenu.contentOverlayView.removeFromSuperview()
        
        self.sideMenu.contentViewCenterConstraint.constant = 0
        
        if animated {
            
            UIView.animate(withDuration: self.sideMenu.menuAnimationDuration, delay: 0, options: self.sideMenu.menuAnimationOptions, animations: {
                
                self.sideMenu.contentContainerView.layer.transform = CATransform3DIdentity
                self.sideMenu.view.layoutSubviews()
                
                }, completion: nil)
            
        } else {
            
            self.sideMenu.contentContainerView.layer.transform = CATransform3DIdentity
            self.sideMenu.view.layoutSubviews()
            
        }
    }
    
    func sideMenu(panGestureRecognized recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.sideMenu.view)
        
        switch recognizer.state {
            
        case .began:
            
            self.initialContentTranslation = self.sideMenu.contentViewCenterConstraint.constant
            
        case .changed:
            
            self.translateContentView(inXDimension: translation.x + self.initialContentTranslation, animated: false)
            
        case .ended:
            
            self.handlePanGestureEnd()
            
        default:
            
            break
            
        }
    }
    
    func handlePanGestureEnd() {
        
        if abs(self.sideMenu.contentViewCenterConstraint.constant) > self.maxAbsoluteContentTranslation / 2.0 {
            
            // Almost opened
            
            if self.sideMenu.contentViewCenterConstraint.constant < 0 {
                self.openRightMenu()
            }
            
            
        } else {
            
            self.hideMenu()
            
        }
        
    }
}
