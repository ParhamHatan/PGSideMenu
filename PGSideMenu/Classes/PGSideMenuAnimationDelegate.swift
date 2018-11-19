//
//  PGSideMenuAnimationDelegate.swift
//  Pods
//
//  Created by Piotr Gorzelany on 11/09/16.
//
//

import Foundation
import UIKit

enum Side {
    case right
}

protocol PGSideMenuAnimationDelegate: class {
    
    init(sideMenu: PGSideMenu)
    
    var sideMenu: PGSideMenu {get}
    
    func toggleRightMenu(animated: Bool)
    var isRightMenuOpen: Bool {get}
    
    func hideMenu(animated: Bool)
    
    func sideMenu(panGestureRecognized: UIPanGestureRecognizer)
}
