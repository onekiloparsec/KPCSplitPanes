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
        var topLevels = NSArray()
        Bundle(for: ViewController.self).loadNibNamed("PaneView", owner: nil, topLevelObjects: &topLevels)
        // one should deal with failure at some point...
        let pv = topLevels.filter({ ($0 as AnyObject).isKind(of: PaneView.self) }).first as! PaneView
        return pv
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var splitView: PanesSplitView?
    let splitViewDelegate = PanesSplitViewDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        UserDefaults.standard.removeObject(forKey: PanesSplitViewSplitSizeWarningShowAgainKey)
        self.splitView?.delegate = self.splitViewDelegate
        self.splitView?.factory = Factory()
    }
}

