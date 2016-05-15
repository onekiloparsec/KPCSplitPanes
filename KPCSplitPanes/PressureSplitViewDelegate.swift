//
//  PressureSplitViewDelegate.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 11/05/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Foundation

public class PressureSplitViewDelegate : NSObject, NSSplitViewDelegate {
    
    public var minimumHeight: CGFloat = 50.0
    public var minimumWidth: CGFloat = 50.0
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