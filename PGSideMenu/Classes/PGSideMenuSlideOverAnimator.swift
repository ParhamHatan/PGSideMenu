//
//  PGSideMenuSlideOverAnimator.swift
//  Pods
//
//  Created by Piotr Gorzelany on 13/09/16.
//
//

import Foundation

class PGSideMenuSlideOverAnimator: PGSideMenuAnimationDelegate {
    
    // MARK: Properties
    
    unowned let sideMenu: PGSideMenu
    
    var isRightMenuOpen: Bool {
        return self.sideMenu.innerContentViewCenterConstraint.constant == -self.maxAbsoluteContentTranslation
    }
    
    var isMenuOpen: Bool {
        return self.isRightMenuOpen
    }
    
    var maxAbsoluteContentTranslation: CGFloat {
        return UIScreen.main.bounds.width * sideMenu.menuPercentWidth
    }
    
    var initialContentTranslation: CGFloat = 0
    
    // MARK: Lifecycle
    
    required init(sideMenu: PGSideMenu) {
        self.sideMenu = sideMenu
        
        self.configureSideMenu()
    }
    
    // MARK: Methods
    
    func configureSideMenu() {
        
        self.sideMenu.rightMenuWidthConstraint.constant = self.maxAbsoluteContentTranslation
        self.sideMenu.innerContentViewCenterConstraint.constant = 0
    }
    
    
    func toggleRightMenu(animated: Bool) {
        
        guard !self.isMenuOpen else {
            self.hideMenu(animated: animated)
            return
        }
        
        self.openRightMenu(animated: animated)
    }
    
    
    func openRightMenu(animated: Bool) {
        
        self.translateContentView(by: -self.maxAbsoluteContentTranslation, animated: animated)
    }
    
    func translateContentView(by x: CGFloat, animated: Bool) {
        
        guard abs(x) <= self.maxAbsoluteContentTranslation else {return}
        
        self.sideMenu.innerContentViewCenterConstraint.constant = x
        self.sideMenu.addContentOverlay()
        
        if animated {
            
            UIView.animate(withDuration: self.sideMenu.menuAnimationDuration, delay: 0, options: self.sideMenu.menuAnimationOptions, animations: {
                
                self.sideMenu.view.layoutIfNeeded()
                
                }, completion: nil)
            
        }
    }
    
    func hideMenu(animated: Bool) {
        
        self.sideMenu.innerContentViewCenterConstraint.constant = 0
        self.sideMenu.contentOverlayView.removeFromSuperview()
        
        if animated {
            
            UIView.animate(withDuration: self.sideMenu.menuAnimationDuration, delay: 0, options: self.sideMenu.menuAnimationOptions, animations: {
                
                self.sideMenu.view.layoutIfNeeded()
                
                }, completion: nil)
            
        }
    }
    
    func sideMenu(panGestureRecognized recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.sideMenu.view)
        
        switch recognizer.state {
            
        case .began:
            self.initialContentTranslation = self.sideMenu.innerContentViewCenterConstraint.constant
        case .changed:
            self.translateContentView(by: translation.x + self.initialContentTranslation, animated: false)
        case .ended:
            self.handlePanGestureEnd()
        default: break
            
        }
    }
    
    func handlePanGestureEnd() {
        
        if abs(self.sideMenu.innerContentViewCenterConstraint.constant) > self.maxAbsoluteContentTranslation / 2.0 {
            
            // Almost opened
            
            if self.sideMenu.innerContentViewCenterConstraint.constant < 0 {
                self.openRightMenu(animated: true)
            }
            
            
        } else {
            
            self.hideMenu(animated: true)
            
        }
    }
    
}
