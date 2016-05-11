//
//  PressureSplitView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import AppKit

let minimumHeight: CGFloat = 350.0
let minimumWidth: CGFloat = 550.0

class PressureSplitView : NSSplitView {
    
    private var verticalPressure: Int = 0
    private var horizontalPressure: Int = 0
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    private func setup() {
        self.dividerStyle = .Thin
        self.autoresizesSubviews = true
        self.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
    }
    
    func canAddSubview(vertically: Bool) -> Bool {
        let viewCount = max(1, (vertically == true) ? self.horizontalPressure : self.verticalPressure)
        let minimumCurrentExtension = CGFloat(viewCount) * ((vertically == true) ? minimumWidth : minimumHeight)
        let minimumAdditionalExtension = (vertically == true) ? minimumWidth : minimumHeight;
        let currentExtension = (vertically == true) ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
        return (currentExtension - minimumCurrentExtension >= minimumAdditionalExtension);
        
    }
    
    override func addSubview(aView: NSView) {
        super.addSubview(aView);
        self.updatePressuresWithView(aView, sign:1);
    }

    override func addSubview(aView: NSView, positioned place: NSWindowOrderingMode, relativeTo otherView: NSView?) {
        super.addSubview(aView, positioned: place, relativeTo: otherView)
        self.updatePressuresWithView(aView, sign:1);
    }
    
    private func updatePressuresWithView(aView: NSView, sign: Int) {
        if (self.vertical) {
            self.horizontalPressure += sign
            if aView.isKindOfClass(NSSplitView) {
                let sv = aView as! NSSplitView
                self.verticalPressure += sign*sv.subviews.count
            }
        }
        else {
            self.verticalPressure += sign
            if aView.isKindOfClass(NSSplitView) {
                let sv = aView as! NSSplitView
                self.horizontalPressure += sign*sv.subviews.count
            }
        }
    }
    
    func removeSubview(aView: NSView) {
        guard self.subviews.contains(aView) else {
            fatalError("Huh....")
        }

        self.updatePressuresWithView(aView, sign: -1)
        aView.removeFromSuperview()
        self.adjustSubviews()        
    }

}
