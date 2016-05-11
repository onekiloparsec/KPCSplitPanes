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
    
    var paneTag : Int = -1
    
    override func removeFromSuperview() {
        if self.superview?.isKindOfClass(PressureSplitView) == true {
            let sv = self.superview as! PressureSplitView
            sv.removeSubview(self)
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if self.closeButton?.image == nil {
            self.closeButton?.image = PressureSplitView.defaultCloseIcon()
        }
        if self.splitButton?.image == nil {
            self.splitButton?.image = PressureSplitView.defaultSplitIcon()
        }
    }
}
