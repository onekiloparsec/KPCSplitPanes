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
    
    func parentSplitView() -> PressureSplitView? {
        var view: NSView? = self
        while view != nil && view?.isKindOfClass(PressureSplitView) == false {
            view = view!.superview
        }
        return view as! PressureSplitView?
    }
    
    override func removeFromSuperview() {
        self.parentSplitView()?.removeSubview(self)
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
        self.parentSplitView()?.close(self)
    }

    func splitPane() {
        self.parentSplitView()?.split(self)
    }
}
