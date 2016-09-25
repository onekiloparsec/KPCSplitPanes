//
//  ViewController.swift
//  KPCSplitPanesDemo
//
//  Created by Cédric Foellmi on 11/05/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Cocoa
import KPCSplitPanes

class ViewController: NSViewController {

    @IBOutlet weak var splitView: PressureSplitView?
    let splitViewDelegate = PressureSplitViewDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        UserDefaults.standard.removeObject(forKey: PressureSplitViewSplitSizeWarningShowAgainKey)
        self.splitView?.delegate = self.splitViewDelegate
    }
}

