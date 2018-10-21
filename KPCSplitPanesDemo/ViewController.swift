//
//  ViewController.swift
//  KPCSplitPanesDemo
//
//  Created by Cédric Foellmi on 11/05/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Cocoa
import KPCSplitPanes

class Factory: PaneViewFactory {
    func newPaneView() -> PaneView {
        var topLevelObjects: NSArray? = NSArray()
        Bundle(for: ViewController.self).loadNibNamed("PaneView", owner: nil, topLevelObjects: &topLevelObjects)
        // one should deal with failure at some point...
        let pv = topLevelObjects!.filter({ ($0 as AnyObject).isKind(of: PaneView.self) }).first as! PaneView
        return pv
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var splitView: PanesStackView?
    let splitViewDelegate = PanesStackViewDelegate()
    @IBOutlet weak var resizeButton: NSButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
//        UserDefaults.standard.removeObject(forKey: PanesStackViewSplitSizeWarningShowAgainKey)
        self.splitView?.delegate = self.splitViewDelegate
        self.splitView?.factory = Factory()
    }

    @IBAction func resizeWindow(sender: Any?) {
        self.splitView?.setFrameSize(NSSize(width: self.splitView!.frame.size.width, height: self.splitView!.frame.size.height*2))
    }
}

