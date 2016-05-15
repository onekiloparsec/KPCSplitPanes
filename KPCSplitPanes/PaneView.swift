//
//  PaneView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import AppKit

class PaneView : NSView {
    
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
    
    override class func requiresConstraintBasedLayout() -> Bool {
        return false
    }

    func parentSplitView() -> PressureSplitView? {
        var view: NSView? = self
        while view != nil && view?.isKindOfClass(PressureSplitView) == false {
            view = view!.superview
        }
        return view as! PressureSplitView?
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.parentSplitView()?.removeSubPaneView(self)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if self.closeButton?.image == nil {
            self.closeButton?.image = PressureSplitView.defaultCloseIcon()
        }
        if self.splitButton?.image == nil {
            self.splitButton?.image = PressureSplitView.defaultSplitIcon()
        }
        
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
}
