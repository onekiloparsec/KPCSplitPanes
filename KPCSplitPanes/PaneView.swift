//
//  PaneView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

@IBDesignable
open class PaneView : NSView {
    
    @IBOutlet open weak var closeButton: NSButton?
    @IBOutlet open weak var splitButton: NSButton?
    @IBOutlet open weak var emptyPaneLabel: NSTextField?
    
    open internal(set) var indexPath: IndexPath? 
    
    static func newPaneView() -> PaneView {
        var topLevels = NSArray()
        Bundle(for: self).loadNibNamed("PaneView", owner: self, topLevelObjects: &topLevels)
        // one should deal with failure at some point...
        let pv = topLevels.filter({ ($0 as AnyObject).isKind(of: PaneView.self) }).first as! PaneView
        pv.autoresizesSubviews = true
        pv.translatesAutoresizingMaskIntoConstraints = true
        pv.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        return pv
    }
    
    override open var acceptsFirstResponder: Bool {
        return true
    }

    override open class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
        
    override open func viewDidMoveToWindow() {
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
    
    func select(_ flag: Bool) {
        self.closeButton?.image = PaneView.closeIcon(flag)
        let horizontal = (self.parentSplitView()?.useHorizontalSplitAsDefault == true)
        self.splitButton?.image = PaneView.splitIcon(horizontal, selected: flag)
    }
    
    override open func flagsChanged(with theEvent: NSEvent) {
        super.flagsChanged(with: theEvent)
        if let parentSplitView = self.parentSplitView() {
            let horizontal = parentSplitView.splitShouldBeVertical() == false
            let selected = (parentSplitView.selectedPaneView == self)
            self.splitButton?.image = PaneView.splitIcon(horizontal, selected: selected)
        }
    }
    
    func enclosedSplitView() -> PanesSplitView? {
        if self.subviews.first is PanesSplitView {
            return self.subviews.first as? PanesSplitView
        }
        return nil
    }
        
    // MARK: - Icons (some troubles using NSBundle(forClass:) in an extension)
    
    static func icon(named name: String, selected: Bool) -> NSImage {
        let b = Bundle(for: self)
        let fullName = name + (selected ? "Selected" : "Deselected")
        let img = NSImage(contentsOf: b.urlForImageResource(fullName)!)!
        img.setName(fullName)
        return img
    }
    
    static open func closeIcon(_ selected: Bool) -> NSImage {
        return PaneView.icon(named: "Close", selected: selected)
    }
    
    static open func splitHorizontalIcon(_ selected: Bool) -> NSImage {
        return PaneView.icon(named: "SplitHorizontal", selected: selected)
    }
    
    static open func splitVerticalIcon(_ selected: Bool) -> NSImage {
        return PaneView.icon(named: "SplitVertical", selected: selected)
    }
    
    static open func splitIcon(_ horizontal: Bool, selected: Bool) -> NSImage {
        return horizontal ? PaneView.splitHorizontalIcon(selected) : PaneView.splitVerticalIcon(selected)
    }
}
