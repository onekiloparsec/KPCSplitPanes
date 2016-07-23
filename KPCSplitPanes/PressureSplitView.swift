//
//  PressureSplitView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

public let PressureSplitViewSplitSizeWarningShowAgainKey = "PressureSplitViewSplitSizeWarningShowAgainKey"

private var once = dispatch_once_t()

public class PressureSplitView : NSSplitView {
    
    public var useHorizontalSplitAsDefault = true
    public private(set) var selectedPaneView: NSView?
    public private(set) var indexPath: NSIndexPath?
    
    // MARK: - Constructors
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    private func setup() {
        self.dividerStyle = .Thin
        self.autoresizesSubviews = true
        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        self.arrangesAllSubviews = true
        #if DEBUG
        dispatch_once(&once) {
            let sud = NSUserDefaults.standardUserDefaults()
            sud.setBool(true, forKey: PressureSplitViewSplitSizeWarningShowAgainKey)
        }
        #endif
    }
    
    // MARK: - Overrides
    
    override public var postsFrameChangedNotifications: Bool {
        get { return true }
        set {}
    }
    
    override public var acceptsFirstResponder: Bool {
        return true
    }
    
    override public class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: NSIndexPath(index: 0))
        if (self.selectedPaneView == nil) {
            self.select(paneView: self.lastPaneSubview())
        }
    }
    
    // MARK: - Selection

    override public func mouseUp(theEvent: NSEvent) {
        let downPoint = self.convertPoint(theEvent.locationInWindow, fromView:nil)
        let clickedSubviews = self.paneSubviews().filter({ NSPointInRect(downPoint, $0.frame) })
        if clickedSubviews.count == 1 && clickedSubviews.first!.isKindOfClass(PaneView) {
            self.select(paneView: clickedSubviews.first! as PaneView)
        }
        super.mouseUp(theEvent)
    }
    
    private func select(paneView pane: PaneView?) {
        self.selectedPaneView = pane
        for paneSubview in self.paneSubviews() {
            paneSubview.select(paneSubview == pane)
        }
        if pane != nil {
            self.window?.makeFirstResponder(pane)
        }
    }
    
    // MARK: - Adding & Removing Subviews

    private func pressure(vertically: Bool) -> Int {
        return (vertically == self.vertical) ? max(self.subviews.count, 1) : 1
    }
    
    private func minimumExtent(vertically: Bool) -> CGFloat {
        guard self.delegate != nil, let delegate = self.delegate as! PressureSplitViewDelegate? else {
            return 1
        }
        return (vertically == true) ? delegate.minimumWidth : delegate.minimumHeight
    }
    
    private func currentExtent(vertically: Bool) -> CGFloat {
        return (vertically == true) ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
    }
    
    private func maximumScreenRect() -> NSRect {
        return self.window!.contentRectForFrameRect(self.window!.screen!.frame)
    }
    
    private func maximumExtent(vertically: Bool) -> CGFloat {
        let rect = self.maximumScreenRect()
        return (self.vertical) ? CGRectGetWidth(rect) : CGRectGetHeight(rect)
    }
    
    // MARK: - Close

    public func close(paneView pane: PaneView) -> Void {
        if self.paneSubviews().count == 1 {
            let alert = NSAlert.alertForLastPane()
            alert.beginSheetModalForWindow(self.window!, completionHandler: { (returnCode) in
                if (returnCode == NSAlertSecondButtonReturn) {
                    self.remove(paneView: pane)
                }
            })
        }
        else {
            self.remove(paneView: pane)
        }
        
        self.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: NSIndexPath(index: 0))
    }
    
    private func remove(paneView pane: PaneView) {
        if pane.parentSplitView()?.paneSubviews().count == 1 {
            pane.parentSplitView()?.removeFromSuperview()
        }
        else {
            pane.removeFromSuperview()
            self.adjustSubviews()
        }
        
        self.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: NSIndexPath(index: 0))
    }
    
    // MARK: - Split

    public func splitShouldBeVertical() -> Bool {
        let useAlt = NSApp.currentEvent?.hasAltKeyPressed()
        return (useAlt == self.useHorizontalSplitAsDefault)
    }
    
    private func canAddSubview() -> Bool {
        let v = self.splitShouldBeVertical()
        return (self.currentExtent(v) - CGFloat(self.pressure(v))*self.minimumExtent(v) >= self.minimumExtent(v));
    }
    
    public func split(paneView pane: PaneView) {
        let mask = self.window?.styleMask;
        if (mask ==  NSFullScreenWindowMask || mask == NSFullSizeContentViewWindowMask) {
            NSBeep();
            return;
        }
        
        let vertical = self.splitShouldBeVertical()
        
        if self.canAddSubview() == true {
            self.splitPaneView(pane, vertically: vertical)
        }
        else {
            let sud = NSUserDefaults.standardUserDefaults()
            if sud.valueForKey(PressureSplitViewSplitSizeWarningShowAgainKey) == nil {
                sud.setBool(true, forKey: PressureSplitViewSplitSizeWarningShowAgainKey)
            }
            if sud.boolForKey(PressureSplitViewSplitSizeWarningShowAgainKey) {
                self.showSplitSizeWarningAlert(pane, vertically: vertical)
            }
            else {
                self.expandWindowAndSplit(paneView: pane, vertically: vertical)
            }
        }
    }
    
    private func showSplitSizeWarningAlert(paneView: PaneView, vertically: Bool) {
        let alert = NSAlert.alert(forMinimumAdditionalExtension: self.minimumExtent(self.vertical),
                                  currentExtent: self.currentExtent(self.vertical),
                                  maximumExtent: self.maximumExtent(self.vertical),
                                  vertical: self.vertical)
    
        alert.beginSheetModalForWindow(self.window!, completionHandler: { (returnCode) in
            if alert.suppressionButton?.state == NSOnState {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setBool(false, forKey: PressureSplitViewSplitSizeWarningShowAgainKey)
            }
            
            if (returnCode == NSAlertSecondButtonReturn) {
                self.expandWindowAndSplit(paneView: paneView, vertically: vertically)
            }
        })
    }
    
    private func expandWindowAndSplit(paneView pane: PaneView, vertically: Bool) {
        let deltaExtension = self.minimumExtent(self.vertical) // WARN: 2?
        var newWindowFrame = self.window!.contentRectForFrameRect(self.window!.frame)
        
        if (vertically) {
            newWindowFrame.origin.x -= deltaExtension/2.0
            newWindowFrame.size.width += deltaExtension
        }
        else {
            newWindowFrame.origin.y -= deltaExtension/2.0
            newWindowFrame.size.height += deltaExtension
        }
        
        newWindowFrame = self.window!.frameRectForContentRect(newWindowFrame)
        
        NSAnimationContext.currentContext().completionHandler = {
            self.splitPaneView(pane, vertically: vertically)
        }
        self.window!.setFrame(newWindowFrame, display:true, animate:true)
    }

    private func splitPaneView(paneView: PaneView, vertically: Bool) {
        
        let parentSplitView = paneView.parentSplitView()
        guard parentSplitView == self else {
            fatalError("Parent SplitView of \(paneView) should be \(self), and it seems it is not.")
        }
        
        let newPaneView = PaneView.newPaneView()
        let newPaneViewIndex = self.indexOfPaneView(paneView)! + 1
        let dividerIndex = max(0, self.indexOfPaneView(paneView)! - 1)
        var dividerPosition: CGFloat = -1
        
        if self.indexOfPaneView(paneView)! == 0 {
            dividerPosition = (self.vertical == true) ? CGRectGetMaxX(paneView.frame) : CGRectGetMaxY(paneView.frame)
        }
        else {
            dividerPosition = (self.vertical == true) ? CGRectGetMinX(paneView.frame) : CGRectGetMinY(paneView.frame)
        }
        
        let newSplitView = PressureSplitView()
        newSplitView.delegate = self.delegate
        newSplitView.vertical = vertically

        if self.vertical == vertically {
            // We are going into the same direction, just add a new pane.
            
            newSplitView.frame = self.frame
            self.superview?.addSubview(newSplitView)
            
            for view in self.paneSubviews() {
                let constraints = view.constraints
                view.removeFromSuperview()
                newSplitView.addSubview(view)
                view.addConstraints(constraints)
            }
            
            newSplitView.insertArrangedSubview(newPaneView, atIndex: newPaneViewIndex)
            newSplitView.adjustSubviews()
            
            let newPaneViews = newSplitView.paneSubviews()
            var paneViewSide = (self.vertical == true) ? CGRectGetWidth(newSplitView.frame) : CGRectGetHeight(newSplitView.frame)
            paneViewSide = paneViewSide / CGFloat(newPaneViews.count) - newSplitView.dividerThickness*CGFloat(newPaneViews.count-1)
            
            for index in 0..<newPaneViews.count-1 {
                newSplitView.setPosition(CGFloat(index+1)*paneViewSide, ofDividerAtIndex: index)
            }
            
            self.removeFromSuperview()
        }
        else {
            // We are going into the opposite direction, replace the original pane by a splitView, 
            // replace the pane, add a new one.

            // First unselect any pane
            self.select(paneView: nil)

            // Prepare newSplitView and add the newPaneView to it
            newSplitView.vertical = vertically
            newSplitView.addSubview(newPaneView)
            
            // Get side size before playing with pane views.
            let paneViewSide = (vertically) ? CGRectGetWidth(paneView.frame) : CGRectGetHeight(paneView.frame)

            // Add the newSplitView after the triggering paneView
            self.insertArrangedSubview(newSplitView, atIndex: newPaneViewIndex)
            self.adjustSubviews()

            // Remove that paneView
            paneView.removeFromSuperview()
            self.adjustSubviews()

            // Re-add that paneView as first member of the newly-inserted newSplitView
            newSplitView.insertArrangedSubview(paneView, atIndex: 0)
            
            // MUST be set before adjustSubviews
            newSplitView.frame = (vertically == true) ?
                CGRectInset(paneView.frame, 0, self.dividerThickness) :
                CGRectInset(paneView.frame, self.dividerThickness, 0)

            // Adjust the newSplitView subviews and set the position of the new divider to the middle
            newSplitView.adjustSubviews()
            newSplitView.setPosition(paneViewSide/2.0, ofDividerAtIndex: 0)
            
            // Re-adjust the position of our own divider that has certainly wiggled around...
            self.setPosition(dividerPosition, ofDividerAtIndex: dividerIndex)
        }
        
        newSplitView.select(paneView: newPaneView)
        newSplitView.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: NSIndexPath(index: 0))
    }
    
    // MARK: - Helpers
    
    private func paneSubviews() -> [PaneView] {
        return self.subviews.filter({ $0.isKindOfClass(PaneView) }).sort({ (first, second) -> Bool in
            return (self.vertical) ?
                (CGRectGetMaxX(first.frame) < CGRectGetMaxX(second.frame)) :
                (CGRectGetMaxY(first.frame) < CGRectGetMaxY(second.frame))
        }) as! [PaneView]
    }
    
    private func lastPaneSubview() -> PaneView? {
        return self.paneSubviews().last
    }
    
    private func indexOfPaneView(paneView: PaneView) -> Int? {
        return self.paneSubviews().indexOf(paneView)
    }

    private func masterSplitView() -> PressureSplitView {
        var splitView: PressureSplitView? = self
        while splitView != nil && splitView?.parentSplitView() != nil {
            splitView = splitView!.parentSplitView()
        }
        return splitView!
    }
    
    private func pressureSplitViewDepth() -> Int {
        var count = 0
        
        var splitView: PressureSplitView? = self
        while splitView != nil && splitView?.parentSplitView() != nil {
            splitView = splitView!.parentSplitView()
            count += 1
        }
        
        return count
    }
    
    private func applyPanesIndexPaths(startingWithIndexPath indexPath: NSIndexPath) {
        self.indexPath = indexPath
        
        var enclosedSplitViewsCount = 0
        for (index, paneView) in self.paneSubviews().enumerate() {
            paneView.indexPath = indexPath.indexPathByAddingIndex(index)
            paneView.emptyPaneLabel!.stringValue = "\(paneView.indexPath!.stringValue())"
            
            // paneView has an enclosed split view.
            if let enclosedSplitView = paneView.enclosedSplitView() {
                let enclosedSplitViewsIndexPath = paneView.indexPath!.indexPathByAddingIndex(enclosedSplitViewsCount)
                enclosedSplitView.applyPanesIndexPaths(startingWithIndexPath: enclosedSplitViewsIndexPath)
                enclosedSplitViewsCount += 1
            }
        }
    }

}

