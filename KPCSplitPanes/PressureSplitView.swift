//
//  PressureSplitView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

public let PressureSplitViewSplitSizeWarningShowAgainKey = "PressureSplitViewSplitSizeWarningShowAgainKey"

public class PressureSplitView : NSSplitView {
    
    public var useHorizontalSplitAsDefault = true
    public private(set) var selectedPaneView: NSView?
        
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
        self.translatesAutoresizingMaskIntoConstraints = false
        self.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        self.arrangesAllSubviews = true
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
        return false
    }
    
    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
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
            let alert = NSAlert()
            alert.alertStyle = .WarningAlertStyle
            alert.messageText = NSLocalizedString("Be careful!", comment: "")
            alert.informativeText = NSLocalizedString("This is the last pane of the split view. Do you confirm you want to close it?", comment: "")
            alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
            alert.addButtonWithTitle(NSLocalizedString("I confirm, close it.", comment: ""))
            alert.beginSheetModalForWindow(self.window!, completionHandler: { (returnCode) in
                if (returnCode == NSAlertSecondButtonReturn) {
                    self.remove(paneView: pane)
                }
            })
        }
        else {
            self.remove(paneView: pane)
        }
    }
    
    private func remove(paneView pane: PaneView) {
        if pane.parentSplitView()?.paneSubviews().count == 1 {
            pane.parentSplitView()?.removeFromSuperview()
        }
        else {
            pane.removeFromSuperview()
        }
    }
    
    // MARK: - Split

    private func splitShouldBeVertical() -> Bool {
        let theEvent = NSApp.currentEvent
        let optionsKey = NSEventModifierFlags(rawValue: theEvent!.modifierFlags.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue)
        let useAlt = (optionsKey == .AlternateKeyMask)
        return (useAlt == false && self.useHorizontalSplitAsDefault == false) || (useAlt == true && self.useHorizontalSplitAsDefault == true)
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
        
        let theEvent = NSApp.currentEvent;
        let optionsKey = NSEventModifierFlags(rawValue: theEvent!.modifierFlags.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue)
        let vertical = (optionsKey == .AlternateKeyMask)
        
        if self.canAddSubview() == true {
            self.splitPaneView(pane, vertically: vertical)
        }
        else {
            if NSUserDefaults.standardUserDefaults().valueForKey(PressureSplitViewSplitSizeWarningShowAgainKey) == nil {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: PressureSplitViewSplitSizeWarningShowAgainKey)
            }
            if NSUserDefaults.standardUserDefaults().boolForKey(PressureSplitViewSplitSizeWarningShowAgainKey) {
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
        let newPaneViewIndex = self.indexOfPaneView(paneView)!+1
        
        let newSplitView = PressureSplitView()
        newSplitView.delegate = self.delegate

        if self.vertical == vertically {
            // We are going into the same direction, just add a new pane.
            
            newSplitView.frame = self.frame
            self.superview?.addSubview(newSplitView)
            
            for view in self.paneSubviews() {
                view.removeFromSuperview()
                newSplitView.addArrangedSubview(view)
            }
            
            newSplitView.insertArrangedSubview(newPaneView, atIndex: newPaneViewIndex)
            newSplitView.select(paneView: newPaneView)
            newSplitView.adjustSubviews()
            
            self.removeFromSuperview()
        }
        else {
            // We are going into the opposite direction, replace the original pane by a splitView, 
            // replace the pane, add a new one.
            
            newSplitView.vertical = vertically
            
            // Get side size before playing with pane views.
            let side = (vertically) ? CGRectGetWidth(paneView.frame) : CGRectGetHeight(paneView.frame)

            self.insertArrangedSubview(newSplitView, atIndex: newPaneViewIndex)
            paneView.removeFromSuperview()
            self.adjustSubviews()
            self.select(paneView: nil)
            
            newSplitView.addSubview(paneView)
            newSplitView.addSubview(newPaneView)
            newSplitView.select(paneView: newPaneView)
            
            // MUST be set before adjustSubviews
            newSplitView.frame = (vertically == true) ?
                CGRectInset(paneView.frame, 0, self.dividerThickness) :
                CGRectInset(paneView.frame, self.dividerThickness, 0)

            newSplitView.adjustSubviews()
            newSplitView.setPosition(side/2.0, ofDividerAtIndex: 0)

            // This is a tricky workaround to force rearrangement of subviews...
//            let pos = (vertically == true) ? CGRectGetHeight(self.frame)/2.0 : CGRectGetWidth(self.frame)/2.0
//            self.setPosition(pos, ofDividerAtIndex: newPaneViewIndex)
        }
        
        newSplitView.window?.makeFirstResponder(newPaneView)
    }
    
    // MARK: - Helpers
    
    // Consider both PaneViews and PressureSplitViews (to also count perpendicular splits).
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
}

// MARK: Alert

private extension NSAlert {
    static func alert(forMinimumAdditionalExtension additionalExtension: CGFloat,
                                                    currentExtent: CGFloat,
                                                    maximumExtent: CGFloat,
                                                    vertical: Bool) -> NSAlert
    {
        let direction = (vertical) ? "horizontally" : "vertically"
        let extensionName = (vertical) ? "width" : "height"
        
        let informativeText = NSMutableString()
        informativeText.appendFormat(NSLocalizedString("A new pane requires a minimum of \(additionalExtension) additional points \(direction).", comment: ""))
        informativeText.appendString(" ")
        informativeText.appendFormat(NSLocalizedString("The current view has a \(extensionName) of \(currentExtent) points.", comment: ""))
        
        informativeText.appendString(" ")
        informativeText.appendFormat(NSLocalizedString("And it can extends to a maximum of \(maximumExtent) points (accounting for window borders).", comment: ""))
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Not enough room to split.", comment: "")
        alert.informativeText = informativeText as String
        alert.showsSuppressionButton = true
        alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        
        if (currentExtent + additionalExtension < maximumExtent) {
            alert.addButtonWithTitle(NSLocalizedString("Adjust window automatically", comment: ""))
        }
        
        return alert
    }
}
