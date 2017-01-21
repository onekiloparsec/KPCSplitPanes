//
//  PressureSplitView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

public let PanesSplitViewSplitSizeWarningShowAgainKey = "PanesSplitViewSplitSizeWarningShowAgainKey"

private var once = Int()

@IBDesignable
open class PanesSplitView : NSSplitView {
    
    open var useHorizontalSplitAsDefault = true
    open fileprivate(set) var selectedPaneView: NSView?
    open fileprivate(set) var indexPath: IndexPath?
    
    open var factory: PaneViewFactory!
    
    // MARK: - Constructors
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    fileprivate func setup() {
        self.dividerStyle = .thin
        self.autoresizesSubviews = true
        self.arrangesAllSubviews = true
        self.translatesAutoresizingMaskIntoConstraints = true
        
        #if DEBUG
        dispatch_once(&once) {
            let sud = NSUserDefaults.standardUserDefaults()
            sud.setBool(true, forKey: PressureSplitViewSplitSizeWarningShowAgainKey)
        }
        #endif
    }
    
    // MARK: - Overrides
    
    override open var postsFrameChangedNotifications: Bool {
        get { return true }
        set {}
    }
    
    override open var acceptsFirstResponder: Bool {
        return true
    }
    
    override open class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if self.window != nil && self.factory == nil {
            Swift.print("[WARN] The PanesSplitView \(self) needs a Pane View Factory to work with. Next split will throw an exception.")
        }
        
        self.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
        if (self.selectedPaneView == nil) {
            self.makeKey(self.lastPaneSubview())
        }
    }
    
    // MARK: - Selection

    override open func mouseUp(with theEvent: NSEvent) {
        let downPoint = self.convert(theEvent.locationInWindow, from:nil)
        let clickedSubviews = self.paneSubviews().filter({ NSPointInRect(downPoint, $0.frame) })
        if clickedSubviews.count == 1 && clickedSubviews.first!.isKind(of: PaneView.self) {
            self.makeKey(clickedSubviews.first! as PaneView)
        }
        super.mouseUp(with: theEvent)
    }
    
    open func makeKey(_ paneView: PaneView?) {
        self.selectedPaneView = paneView
        for paneSubview in self.paneSubviews() {
            paneSubview.makeKey(paneSubview == paneView)
        }
//        if paneView != nil {
//            self.window?.makeFirstResponder(paneView)
//        }
    }
    
    // MARK: - Adding & Removing Subviews

    fileprivate func pressure(_ vertically: Bool) -> Int {
        return (vertically == self.isVertical) ? max(self.subviews.count, 1) : 1
    }
    
    fileprivate func minimumExtent(_ vertically: Bool) -> CGFloat {
        guard self.delegate != nil, let delegate = self.delegate as! PanesSplitViewDelegate? else {
            return 1
        }
        return (vertically == true) ? delegate.minimumWidth : delegate.minimumHeight
    }
    
    fileprivate func currentExtent(_ vertically: Bool) -> CGFloat {
        return (vertically == true) ? self.frame.width : self.frame.height;
    }
    
    fileprivate func maximumScreenRect() -> NSRect {
        return self.window!.contentRect(forFrameRect: self.window!.screen!.frame)
    }
    
    fileprivate func maximumExtent(_ vertically: Bool) -> CGFloat {
        let rect = self.maximumScreenRect()
        return (self.isVertical) ? rect.width : rect.height
    }
    
    // MARK: - Close

    open func close(paneView pane: PaneView) -> Void {
        if self.delegate is PanesSplitViewDelegateProtocol {
            let paneDelegate = self.delegate as! PanesSplitViewDelegateProtocol
            if paneDelegate.paneSplitView?(self, shouldRemove: pane) == false {
                return
            }
        }
        
        if self.paneSubviews().count == 1 {
            let alert = NSAlert.alertForLastPane()
            alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode) in
                if (returnCode == NSAlertSecondButtonReturn) {
                    self.remove(paneView: pane)
                }
            })
        }
        else {
            self.remove(paneView: pane)
        }
        
        self.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
    }
    
    fileprivate func remove(paneView pane: PaneView) {
        if self.delegate is PanesSplitViewDelegateProtocol {
            let paneDelegate = self.delegate as! PanesSplitViewDelegateProtocol
            paneDelegate.paneSplitView?(self, willRemove: pane)
        }

        if pane.parentSplitView()?.paneSubviews().count == 1 {
            pane.parentSplitView()?.removeFromSuperview()
        }
        else {
            pane.removeFromSuperview()
            self.adjustSubviews()
        }
        
        self.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
        
        if self.delegate is PanesSplitViewDelegateProtocol {
            let paneDelegate = self.delegate as! PanesSplitViewDelegateProtocol
            paneDelegate.paneSplitView?(self, didRemove: pane)
        }
    }
    
    // MARK: - Split

    open func splitShouldBeVertical() -> Bool {
        let useAlt = NSApp.currentEvent?.hasAltKeyPressed()
        return (useAlt == self.useHorizontalSplitAsDefault)
    }
    
    fileprivate func canAddSubview() -> Bool {
        let v = self.splitShouldBeVertical()
        return (self.currentExtent(v) - CGFloat(self.pressure(v))*self.minimumExtent(v) >= self.minimumExtent(v));
    }
    
    open func split(paneView pane: PaneView) {
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
            let sud = UserDefaults.standard
            if sud.value(forKey: PanesSplitViewSplitSizeWarningShowAgainKey) == nil {
                sud.set(true, forKey: PanesSplitViewSplitSizeWarningShowAgainKey)
            }
            if sud.bool(forKey: PanesSplitViewSplitSizeWarningShowAgainKey) {
                self.showSplitSizeWarningAlert(pane, vertically: vertical)
            }
            else {
                self.expandWindowAndSplit(paneView: pane, vertically: vertical)
            }
        }
    }
    
    fileprivate func showSplitSizeWarningAlert(_ paneView: PaneView, vertically: Bool) {
        let alert = NSAlert.alert(forMinimumAdditionalExtension: self.minimumExtent(self.isVertical),
                                  currentExtent: self.currentExtent(self.isVertical),
                                  maximumExtent: self.maximumExtent(self.isVertical),
                                  vertical: self.isVertical)
    
        alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode) in
            if alert.suppressionButton?.state == NSOnState {
                let defaults = UserDefaults.standard
                defaults.set(false, forKey: PanesSplitViewSplitSizeWarningShowAgainKey)
            }
            
            if (returnCode == NSAlertSecondButtonReturn) {
                self.expandWindowAndSplit(paneView: paneView, vertically: vertically)
            }
        })
    }
    
    fileprivate func expandWindowAndSplit(paneView pane: PaneView, vertically: Bool) {
        let deltaExtension = self.minimumExtent(self.isVertical) // WARN: 2?
        var newWindowFrame = self.window!.frame
        
        if (vertically) {
            newWindowFrame.origin.x -= deltaExtension/2.0
            newWindowFrame.size.width += deltaExtension
        }
        else {
            newWindowFrame.origin.y -= deltaExtension/2.0
            newWindowFrame.size.height += deltaExtension
        }
        
        NSAnimationContext.current().completionHandler = {
            self.splitPaneView(pane, vertically: vertically)
        }
        self.window!.setFrame(newWindowFrame, display:true, animate:true)
    }

    fileprivate func splitPaneView(_ paneView: PaneView, vertically: Bool) {
        
        let parentSplitView = paneView.parentSplitView()
        guard parentSplitView === self else {
            fatalError("Parent SplitView of \(paneView) should be \(self), and it seems it is not.")
        }
        
        let paneViewIndex = self.indexOfPaneView(paneView)!
        let dividerPosition = self.dividerPosition(forPaneView: paneView)

        let newPaneView = self.factory.newPaneView()
        var newSplitView: PanesSplitView!
        if let sv = self.factory.newPaneSplitView?() {
            newSplitView = sv
        }
        else {
            newSplitView = PanesSplitView()
        }
        
        newSplitView.factory = self.factory
        newSplitView.delegate = self.delegate
        newSplitView.isVertical = vertically
        newSplitView.autoresizingMask = self.autoresizingMask
        newSplitView.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints

        if self.isVertical == vertically {
            // We are going into the same direction, just add a new pane.
            
            newSplitView.frame = self.frame
            self.superview?.addSubview(newSplitView)
            self.removeFromSuperview()
            
            if self.superview is NSSplitView {
                let sv = self.superview as! NSSplitView
                sv.adjustSubviews()
            }
            
            for view in self.paneSubviews() {
                view.removeFromSuperview()
                newSplitView.addSubview(view)
            }
            
            newSplitView.insertArrangedSubview(newPaneView, at: paneViewIndex + 1)
            newSplitView.adjustSubviews()
            
            let newPaneViews = newSplitView.paneSubviews()
            var paneViewSide = (self.isVertical == true) ? newSplitView.frame.width : newSplitView.frame.height
            paneViewSide = paneViewSide / CGFloat(newPaneViews.count) - newSplitView.dividerThickness*CGFloat(newPaneViews.count-1)
            
            for index in 0..<newPaneViews.count-1 {
                newSplitView.setPosition(CGFloat(index+1)*paneViewSide, ofDividerAt: index)
            }
        }
        else {
            // We are going into the opposite direction, replace the original pane by a splitView, 
            // put the original pane inside the newSplitView, and add a new one.

            // First unselect any pane
            self.makeKey(nil)
            
            //
            let dividerIndex = max(0, paneViewIndex - 1)

            // Prepare newSplitView and add the newPaneView to it
            newSplitView.isVertical = vertically
            newSplitView.addSubview(newPaneView)
            
            // Get side size before playing with pane views.
            let paneViewSide = (vertically) ? paneView.frame.width : paneView.frame.height

            // Add the newSplitView after the triggering paneView
            self.insertArrangedSubview(newSplitView, at: paneViewIndex + 1)
            self.adjustSubviews()

            // Remove that paneView
            paneView.removeFromSuperview()
            self.adjustSubviews()

            // Re-add that paneView as first member of the newly-inserted newSplitView
            newSplitView.insertArrangedSubview(paneView, at: 0)
            
            // MUST be set before adjustSubviews
            newSplitView.frame = (vertically == true) ?
                paneView.frame.insetBy(dx: 0, dy: self.dividerThickness) :
                paneView.frame.insetBy(dx: self.dividerThickness, dy: 0)

            // Adjust the newSplitView subviews and set the position of the new divider to the middle
            newSplitView.adjustSubviews()
            newSplitView.setPosition(paneViewSide/2.0, ofDividerAt: 0)
            
            // Re-adjust the position of our own divider that has certainly wiggled around...
            self.setPosition(dividerPosition, ofDividerAt: dividerIndex)
        }
        
        newSplitView.makeKey(newPaneView)
        newSplitView.masterSplitView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
    }
    
    // MARK: - Helpers
    
    fileprivate func dividerPosition(forPaneView paneView: PaneView) -> CGFloat {
        var dividerPosition: CGFloat = -1
        
        if self.indexOfPaneView(paneView)! == 0 {
            dividerPosition = (self.isVertical == true) ? paneView.frame.maxX : paneView.frame.maxY
        }
        else {
            dividerPosition = (self.isVertical == true) ? paneView.frame.minX : paneView.frame.minY
        }

        return dividerPosition
    }
    
    fileprivate func paneSubviews() -> [PaneView] {
        return self.subviews.filter({ $0.isKind(of: PaneView.self) }).sorted(by: { (first, second) -> Bool in
            return (self.isVertical) ?
                (first.frame.maxX < second.frame.maxX) :
                (first.frame.maxY < second.frame.maxY)
        }) as! [PaneView]
    }
    
    fileprivate func lastPaneSubview() -> PaneView? {
        return self.paneSubviews().last
    }
    
    fileprivate func indexOfPaneView(_ paneView: PaneView) -> Int? {
        return self.paneSubviews().index(of: paneView)
    }

    fileprivate func masterSplitView() -> PanesSplitView {
        var splitView: PanesSplitView? = self
        while splitView != nil && splitView?.parentSplitView() != nil {
            splitView = splitView!.parentSplitView()
        }
        return splitView!
    }
    
    fileprivate func pressureSplitViewDepth() -> Int {
        var count = 0
        
        var splitView: PanesSplitView? = self
        while splitView != nil && splitView?.parentSplitView() != nil {
            splitView = splitView!.parentSplitView()
            count += 1
        }
        
        return count
    }
    
    fileprivate func applyPanesIndexPaths(startingWithIndexPath indexPath: IndexPath) {
        self.indexPath = indexPath
        
        var enclosedSplitViewsCount = 0
        for (index, paneView) in self.paneSubviews().enumerated() {
            paneView.indexPath = indexPath.appending(index)
            
            // paneView has an enclosed split view.
            if let enclosedSplitView = paneView.enclosedSplitView() {
                let enclosedSplitViewsIndexPath = paneView.indexPath!.appending(enclosedSplitViewsCount)
                enclosedSplitView.applyPanesIndexPaths(startingWithIndexPath: enclosedSplitViewsIndexPath)
                enclosedSplitViewsCount += 1
            }
        }
    }

}

