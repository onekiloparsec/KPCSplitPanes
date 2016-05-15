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
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        self.splitView?.delegate = self.splitViewDelegate
    }
}

