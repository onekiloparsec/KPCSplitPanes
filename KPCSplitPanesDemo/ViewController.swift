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
    var splitViewDelegate: PressureSplitViewDelegate?
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.splitViewDelegate = PressureSplitViewDelegate()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.splitViewDelegate = PressureSplitViewDelegate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        
        self.splitView?.delegate = self.splitViewDelegate
    }
}

