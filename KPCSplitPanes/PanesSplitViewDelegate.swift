//
//  PressureStackViewDelegate.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 11/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

@objc public protocol PanesStackViewDelegateProtocol : NSStackViewDelegate {
    @objc optional func paneStackView(_ splitView: PanesStackView, shouldRemove paneView: PaneView) -> Bool
    @objc optional func paneStackView(_ splitView: PanesStackView, willRemove paneView: PaneView)
    @objc optional func paneStackView(_ splitView: PanesStackView, didRemove paneView: PaneView)
}

open class PanesStackViewDelegate : NSObject, PanesStackViewDelegateProtocol {
    
    open var minimumHeight: CGFloat = 100.0
    open var minimumWidth: CGFloat = 100.0
    open var canCollapse: Bool = false
    
    open func splitView(_ splitView: NSStackView, canCollapseSubview subview: NSView) -> Bool {
        return canCollapse
    }
    
//    open func splitView(_ splitView: NSStackView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
//        var minimum = CGFloat(0.0)
//        if splitView.isKind(of: PanesStackView.self) {
//            minimum = (splitView.isVertical == true) ? minimumWidth : minimumHeight
//        }
//        return proposedMaximumPosition - minimum
//    }
//    
//    open func splitView(_ splitView: NSStackView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
//        var maximum = CGFloat(0.0)
//        if splitView.isKind(of: PanesStackView.self) {
//            maximum = (splitView.isVertical == true) ? minimumWidth : minimumHeight
//        }
//        return proposedMinimumPosition + maximum
//    }
}
