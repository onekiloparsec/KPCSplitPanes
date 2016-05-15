//
//  PressureSplitViewDelegate.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 11/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

public class PressureSplitViewDelegate : NSObject, NSSplitViewDelegate {
    
    public var minimumHeight: CGFloat = 100.0
    public var minimumWidth: CGFloat = 100.0
    public var canCollapse: Bool = false
    
    public func splitView(splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return canCollapse
    }
    
    public func splitView(splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        var minimum = CGFloat(0.0)
        if splitView.isKindOfClass(PressureSplitView) {
            minimum = (splitView.vertical == true) ? minimumWidth : minimumHeight
        }
        return proposedMaximumPosition - minimum
    }
    
    public func splitView(splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        var maximum = CGFloat(0.0)
        if splitView.isKindOfClass(PressureSplitView) {
            maximum = (splitView.vertical == true) ? minimumWidth : minimumHeight
        }
        return proposedMinimumPosition + maximum
    }
}