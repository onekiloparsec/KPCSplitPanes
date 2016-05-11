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

public class PressureSplitView : NSSplitView {
    
    private var verticalPressure: Int = 0
    private var horizontalPressure: Int = 0
    
    private static func defaultIcon(named name: String) -> NSImage {
        let b = NSBundle(forClass: self)
        return NSImage(contentsOfURL: b.URLForImageResource(name)!)!
    }
    static func defaultCloseIcon() -> NSImage {
        return self.defaultIcon(named: "CloseCrossIcon")
    }
    static func defaultSplitIcon() -> NSImage {
        return self.defaultIcon(named: "SplitHorizontalRectIcon")
    }
    static func defaultAlternateSplitIcon() -> NSImage {
        return self.defaultIcon(named: "SplitVerticalRectIcon")
    }
    
    required public init?(coder: NSCoder) {
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
    
    override public var acceptsFirstResponder: Bool {
        return true
    }
    
    private func paneSubviews() -> Array<PaneView> {
        var subPaneViews = self.subviews as Array<NSView>
        subPaneViews = subPaneViews.filter({ $0.isKindOfClass(PaneView) })
        return subPaneViews as! Array<PaneView>
    }
    
    public override func flagsChanged(theEvent: NSEvent) {
        let optionsKey = NSEventModifierFlags(rawValue: theEvent.modifierFlags.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue)
        for paneView in self.paneSubviews() {
            paneView.splitButton?.image = (optionsKey == .AlternateKeyMask) ? PressureSplitView.defaultAlternateSplitIcon() : PressureSplitView.defaultSplitIcon()
        }
    }

    func canAddSubview(vertically: Bool) -> Bool {
        let viewCount = max(1, (vertically == true) ? self.horizontalPressure : self.verticalPressure)
        let minimumCurrentExtension = CGFloat(viewCount) * ((vertically == true) ? minimumWidth : minimumHeight)
        let minimumAdditionalExtension = (vertically == true) ? minimumWidth : minimumHeight;
        let currentExtension = (vertically == true) ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
        return (currentExtension - minimumCurrentExtension >= minimumAdditionalExtension);
        
    }
    
    override public func addSubview(aView: NSView) {
        super.addSubview(aView);
        self.updatePressuresWithView(aView, sign:1);
    }

    override public func addSubview(aView: NSView, positioned place: NSWindowOrderingMode, relativeTo otherView: NSView?) {
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
