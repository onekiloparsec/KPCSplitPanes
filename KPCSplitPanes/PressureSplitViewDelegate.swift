//
//  PressureSplitViewDelegate.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 11/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

open class PressureSplitViewDelegate : NSObject, NSSplitViewDelegate {
    
    open var minimumHeight: CGFloat = 100.0
    open var minimumWidth: CGFloat = 100.0
    open var canCollapse: Bool = false
    
    open func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return canCollapse
    }
    
    open func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        var minimum = CGFloat(0.0)
        if splitView.isKind(of: PressureSplitView.self) {
            minimum = (splitView.isVertical == true) ? minimumWidth : minimumHeight
        }
        return proposedMaximumPosition - minimum
    }
    
    open func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        var maximum = CGFloat(0.0)
        if splitView.isKind(of: PressureSplitView.self) {
            maximum = (splitView.isVertical == true) ? minimumWidth : minimumHeight
        }
        return proposedMinimumPosition + maximum
    }
}
