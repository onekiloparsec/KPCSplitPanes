//
//  PressureStackView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

public let PanesStackViewSplitSizeWarningShowAgainKey = "PanesStackViewSplitSizeWarningShowAgainKey"
public let PanesStackViewUnmakeKeyNotification = Notification.Name("PanesStackViewUnmakeKeyNotification")

private var once = Int()

extension NSStackView {
    public var isVertical: Bool {
        get { return self.orientation == .vertical }
        set { self.orientation = (newValue) ? .vertical : .horizontal }
    }
}

@IBDesignable
open class PanesStackView : NSStackView {
    
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
//        self.dividerStyle = .thin
        self.autoresizesSubviews = true
//        self.arrangesAllSubviews = true
//        self.translatesAutoresizingMaskIntoConstraints = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(unmakeKey),
                                               name: PanesStackViewUnmakeKeyNotification,
                                               object: nil)
        
        #if DEBUG
        dispatch_once(&once) {
            let sud = NSUserDefaults.standardUserDefaults()
            sud.setBool(true, forKey: PressureStackViewSplitSizeWarningShowAgainKey)
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
    
    override open class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if self.window != nil && self.factory == nil {
            Swift.print("[WARN] The PanesStackView \(self) needs a Pane View Factory to work with. Next split will throw an exception.")
        }
        
        self.masterStackView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
        if (self.selectedPaneView == nil) {
            self.makeKey(self.lastPaneSubview())
        }
    }
    
    // MARK: - Selection

    override open func mouseUp(with theEvent: NSEvent) {
        let downPoint = self.convert(theEvent.locationInWindow, from:nil)
        let clickedSubviews = self.paneSubviews().filter({ NSPointInRect(downPoint, $0.frame) })
        if clickedSubviews.count == 1 && clickedSubviews.first!.isKind(of: PaneView.self) {
            NotificationCenter.default.post(name: PanesStackViewUnmakeKeyNotification, object: nil)
            self.makeKey(clickedSubviews.first! as PaneView)
        }
        super.mouseUp(with: theEvent)
    }

    @objc open func unmakeKey() {
        self.selectedPaneView = nil
        for paneSubview in self.paneSubviews() {
            paneSubview.makeKey(false)
        }
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
        guard self.delegate != nil, let delegate = self.delegate as! PanesStackViewDelegate? else {
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
        if self.delegate is PanesStackViewDelegateProtocol {
            let paneDelegate = self.delegate as! PanesStackViewDelegateProtocol
            if paneDelegate.paneStackView?(self, shouldRemove: pane) == false {
                return
            }
        }
        
        if self.paneSubviews().count == 1 {
            let alert = NSAlert.alertForLastPane()
            alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode) in
                if (returnCode == NSApplication.ModalResponse.alertSecondButtonReturn) {
                    self.remove(paneView: pane)
                }
            })
        }
        else {
            self.remove(paneView: pane)
        }
        
        self.masterStackView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
    }
    
    fileprivate func remove(paneView pane: PaneView) {
        if self.delegate is PanesStackViewDelegateProtocol {
            let paneDelegate = self.delegate as! PanesStackViewDelegateProtocol
            paneDelegate.paneStackView?(self, willRemove: pane)
        }

        if pane.parentStackView()?.paneSubviews().count == 1 {
            pane.parentStackView()?.removeFromSuperview()
        }
        else {
            pane.removeFromSuperview()
        }
        
        self.masterStackView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
        
        if self.delegate is PanesStackViewDelegateProtocol {
            let paneDelegate = self.delegate as! PanesStackViewDelegateProtocol
            paneDelegate.paneStackView?(self, didRemove: pane)
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
        // TODO: check this
//        let mask = self.window?.styleMask;
//        if (mask ==  NSFullScreenWindowMask || mask == NSFullSizeContentViewWindowMask) {
//            NSBeep();
//            return;
//        }
        
        let vertical = self.splitShouldBeVertical()
        
        if self.canAddSubview() == true {
            self.splitPaneView(pane, vertically: vertical)
        }
        else {
            let sud = UserDefaults.standard
            if sud.value(forKey: PanesStackViewSplitSizeWarningShowAgainKey) == nil {
                sud.set(true, forKey: PanesStackViewSplitSizeWarningShowAgainKey)
            }
            if sud.bool(forKey: PanesStackViewSplitSizeWarningShowAgainKey) {
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
            if alert.suppressionButton!.state == .on {
                let defaults = UserDefaults.standard
                defaults.set(false, forKey: PanesStackViewSplitSizeWarningShowAgainKey)
            }
            
            if (returnCode == NSApplication.ModalResponse.alertSecondButtonReturn) {
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
        
        NSAnimationContext.current.completionHandler = {
            self.splitPaneView(pane, vertically: vertically)
        }
        self.window!.setFrame(newWindowFrame, display:true, animate:true)
    }

    fileprivate func splitPaneView(_ paneView: PaneView, vertically: Bool) {
        
        let parentStackView = paneView.parentStackView()
        guard parentStackView === self else {
            fatalError("Parent StackView of \(paneView) should be \(self), and it seems it is not.")
        }
        
        let paneViewIndex = self.indexOfPaneView(paneView)!
//        let dividerPosition = self.dividerPosition(forPaneView: paneView)

        let newPaneView = self.factory.newPaneView()
        var newStackView: PanesStackView!
        if let sv = self.factory.newPaneStackView?() {
            newStackView = sv
        }
        else {
            newStackView = PanesStackView()
        }
        
        newStackView.factory = self.factory
        newStackView.delegate = self.delegate
        newStackView.isVertical = vertically
        newStackView.autoresizingMask = self.autoresizingMask
//        newStackView.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints

        if self.isVertical == vertically {
            // We are going into the same direction, just add a new pane.
            
            newStackView.frame = self.frame
            self.superview?.addSubview(newStackView)
            self.removeFromSuperview()
            
//            if self.superview is NSStackView {
//                let sv = self.superview as! NSStackView
//            }
            
            for view in self.paneSubviews() {
                view.removeFromSuperview()
                newStackView.addSubview(view)
            }
            
            newStackView.insertArrangedSubview(newPaneView, at: paneViewIndex + 1)
            
//            let newPaneViews = newStackView.paneSubviews()
//            var paneViewSide = (self.isVertical) ? newStackView.frame.width : newStackView.frame.height
//            paneViewSide = paneViewSide / CGFloat(newPaneViews.count)
            
//            for index in 0..<newPaneViews.count-1 {
//                newStackView.setPosition(CGFloat(index+1)*paneViewSide, ofDividerAt: index)
//            }
        }
        else {
            // We are going into the opposite direction, replace the original pane by a splitView, 
            // put the original pane inside the newStackView, and add a new one.

            // First unselect any pane
            self.makeKey(nil)
            
            // Prepare newStackView and add the newPaneView to it
            newStackView.isVertical = vertically
            newStackView.addSubview(newPaneView)
            
            // Compute newPaneView side size before playing with pane views.
//            var newPaneViewSide = (vertically) ? paneView.frame.width : paneView.frame.height
//            newPaneViewSide = newPaneViewSide / 2.0 - newStackView.dividerThickness // It's new. Necessarily, subPaneViews.count = 2

            // Add the newStackView after the triggering paneView
            self.insertArrangedSubview(newStackView, at: paneViewIndex + 1)
//            self.adjustSubviews()

            // Store the actual paneView side size (used below, to be re-applied).
//            let paneViewSide = (self.isVertical) ? paneView.frame.width : paneView.frame.height

            // Remove that paneView
            paneView.removeFromSuperview()
//            self.adjustSubviews()

            // Re-add that paneView as first member of the newly-inserted newStackView
            newStackView.insertArrangedSubview(paneView, at: 0)
            
            // MUST be set before adjustSubviews
//            newStackView.frame = (vertically == true) ?
//                paneView.frame.insetBy(dx: 0, dy: self.dividerThickness) :
//                paneView.frame.insetBy(dx: self.dividerThickness, dy: 0)

            // Adjust the newStackView subviews and set the position of the new divider to the middle
//            newStackView.adjustSubviews()
//            newStackView.setPosition(newPaneViewSide, ofDividerAt: 0)
            
            // Re-adjust the position of our own divider that has certainly wiggled around...
//            for index in 0..<self.paneSubviews().count-1 {
//                self.setPosition(CGFloat(index+1)*paneViewSide, ofDividerAt: index)
//            }

            // White magic
//            self.adjustSubviews()
        }
        
        newStackView.makeKey(newPaneView)
        newStackView.masterStackView().applyPanesIndexPaths(startingWithIndexPath: IndexPath(index: 0))
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

    fileprivate func masterStackView() -> PanesStackView {
        var splitView: PanesStackView? = self
        while splitView != nil && splitView?.parentStackView() != nil {
            splitView = splitView!.parentStackView()
        }
        return splitView!
    }
    
    fileprivate func pressureStackViewDepth() -> Int {
        var count = 0
        
        var splitView: PanesStackView? = self
        while splitView != nil && splitView?.parentStackView() != nil {
            splitView = splitView!.parentStackView()
            count += 1
        }
        
        return count
    }
    
    fileprivate func applyPanesIndexPaths(startingWithIndexPath indexPath: IndexPath) {
        self.indexPath = indexPath
        
        var enclosedStackViewsCount = 0
        for (index, paneView) in self.paneSubviews().enumerated() {
            paneView.indexPath = indexPath.appending(index)
            
            // paneView has an enclosed split view.
            if let enclosedStackView = paneView.enclosedStackView() {
                let enclosedStackViewsIndexPath = paneView.indexPath!.appending(enclosedStackViewsCount)
                enclosedStackView.applyPanesIndexPaths(startingWithIndexPath: enclosedStackViewsIndexPath)
                enclosedStackViewsCount += 1
            }
        }
    }

}


// Helper function inserted by Swift 4.2 migrator.
//fileprivate func convertFromNSControlStateValue(_ input: NSControl.StateValue) -> Int {
//    return input.rawValue
//}
