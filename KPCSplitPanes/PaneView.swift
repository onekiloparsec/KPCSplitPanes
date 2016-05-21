//
//  PaneView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

public class PaneView : NSView {
    
    @IBOutlet weak var closeButton: NSButton?
    @IBOutlet weak var splitButton: NSButton?
    
    static func newPaneView() -> PaneView {
        var topLevels = NSArray?()
        NSBundle(forClass: self).loadNibNamed("PaneView", owner: self, topLevelObjects: &topLevels)
        let pv = topLevels!.filter({ $0.isKindOfClass(PaneView) })[0] as! PaneView
        pv.autoresizesSubviews = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        return pv
    }
    
    override public var acceptsFirstResponder: Bool {
        return true
    }

    override public class func requiresConstraintBasedLayout() -> Bool {
        return false
    }
        
    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        self.closeButton?.image = PaneView.closeIcon(false)
        self.splitButton?.image = PaneView.splitIcon(self.parentSplitView()?.useHorizontalSplitAsDefault==true, selected: false)
        
        self.closeButton?.target = self
        self.closeButton?.action = #selector(PaneView.closePane)
        
        self.splitButton?.target = self
        self.splitButton?.action = #selector(PaneView.splitPane)
    }
    
    func closePane() {
        self.parentSplitView()?.close(paneView: self)
    }

    func splitPane() {
        self.parentSplitView()?.split(paneView: self)
    }
    
    func select(flag: Bool) {
        self.closeButton?.image = PaneView.closeIcon(flag)
        self.splitButton?.image = PaneView.splitIcon(self.parentSplitView()?.useHorizontalSplitAsDefault==true, selected: flag)
    }
    
    override public func flagsChanged(theEvent: NSEvent) {
        let optionsKey = NSEventModifierFlags(rawValue: theEvent.modifierFlags.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue)
        let useAlt = (optionsKey == .AlternateKeyMask)
        let defaultHorizontal = self.parentSplitView()?.useHorizontalSplitAsDefault == true
        let horizontal = (useAlt == false && defaultHorizontal == true) || (useAlt == true && defaultHorizontal == false)
        let selected = (self.parentSplitView()?.selectedPaneView == self)
        self.splitButton?.image = PaneView.splitIcon(horizontal, selected: selected)
    }
    
    // MARK: Helpers
    
    func parentSplitView() -> PressureSplitView? {
        var view: NSView? = self
        while view != nil && view?.isKindOfClass(PressureSplitView) == false {
            view = view!.superview
        }
        return view as! PressureSplitView?
    }
    
    // MARK: - Icons (some troubles using NSBundle(forClass:) in an extension)
    
    static func icon(named name: String, selected: Bool) -> NSImage {
        let b = NSBundle(forClass: self)
        let fullName = name + (selected ? "Selected" : "Deselected")
        let img = NSImage(contentsOfURL: b.URLForImageResource(fullName)!)!
        img.setName(fullName)
        return img
    }
    
    static public func closeIcon(selected: Bool) -> NSImage {
        return PaneView.icon(named: "Close", selected: selected)
    }
    
    static public func splitHorizontalIcon(selected: Bool) -> NSImage {
        return PaneView.icon(named: "SplitHorizontal", selected: selected)
    }
    
    static public func splitVerticalIcon(selected: Bool) -> NSImage {
        return PaneView.icon(named: "SplitVertical", selected: selected)
    }
    
    static public func splitIcon(horizontal: Bool, selected: Bool) -> NSImage {
        return horizontal ? PaneView.splitHorizontalIcon(selected) : PaneView.splitVerticalIcon(selected)
    }
}
