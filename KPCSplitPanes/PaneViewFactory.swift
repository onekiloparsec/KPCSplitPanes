//
//  PaneViewFactory.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 07/01/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import AppKit

@objc public protocol PaneViewFactory {
    func newPaneView() -> PaneView

    @objc optional
    func newPaneSplitView() -> PanesSplitView
}
