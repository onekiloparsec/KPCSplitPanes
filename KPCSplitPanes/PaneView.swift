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
    
    open internal(set) var indexPath: IndexPath? {
        didSet {
            #if DEBUG
            if let label = self.emptyPaneLabel, let ip = self.indexPath {
                label.stringValue = String(describing: ip)
            }
            #endif
        }
    }
        
    override open var acceptsFirstResponder: Bool {
        return true
    }

//    override open class func requiresConstraintBasedLayout() -> Bool {
//        return false
//    }
    
    override open func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        
        if newWindow != nil {
            self.autoresizesSubviews = true
            self.translatesAutoresizingMaskIntoConstraints = true
            self.autoresizingMask = [.width, .height, .maxXMargin, .maxYMargin]
        }
    }
    
    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        self.closeButton?.image = PaneView.closeIcon(selected: false)
        self.splitButton?.image = PaneView.splitIcon(self.parentStackView()?.useHorizontalSplitAsDefault==true, selected: false)
        
        self.closeButton?.target = self
        self.closeButton?.action = #selector(PaneView.closePane)
        
        self.splitButton?.target = self
        self.splitButton?.action = #selector(PaneView.splitPane)
    }
    
    @objc func closePane() {
        self.parentStackView()?.close(paneView: self)
    }

    @objc func splitPane() {
        self.parentStackView()?.split(paneView: self)
    }
    
    func makeKey(_ flag: Bool) {
        self.closeButton?.image = PaneView.closeIcon(selected: flag)
        let horizontal = (self.parentStackView()?.useHorizontalSplitAsDefault == true)
        self.splitButton?.image = PaneView.splitIcon(horizontal, selected: flag)
    }
    
    override open func flagsChanged(with theEvent: NSEvent) {
        super.flagsChanged(with: theEvent)
        if let parentStackView = self.parentStackView() {
            let horizontal = parentStackView.splitShouldBeVertical() == false
            let selected = (parentStackView.selectedPaneView == self)
            self.splitButton?.image = PaneView.splitIcon(horizontal, selected: selected)
        }
    }
    
    func enclosedStackView() -> PanesStackView? {
        if self.subviews.first is PanesStackView {
            return self.subviews.first as? PanesStackView
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
    
    static public func closeIcon(selected: Bool) -> NSImage {
        return PaneView.icon(named: "Close", selected: selected)
    }
    
    static public func splitHorizontalIcon(selected: Bool) -> NSImage {
        return PaneView.icon(named: "SplitHorizontal", selected: selected)
    }
    
    static public func splitVerticalIcon(selected: Bool) -> NSImage {
        return PaneView.icon(named: "SplitVertical", selected: selected)
    }
    
    static public func splitIcon(_ horizontal: Bool, selected: Bool) -> NSImage {
        return horizontal ? PaneView.splitHorizontalIcon(selected: selected) : PaneView.splitVerticalIcon(selected: selected)
    }
}
