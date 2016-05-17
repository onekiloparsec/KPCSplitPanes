//
//  PressureSplitView.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 10/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

let PressureSplitViewSplitSizeWarningShowAgainKey = "PressureSplitViewSplitSizeWarningShowAgainKey"

public class PressureSplitView : NSSplitView {
    
    public var useHorizontalSplitAsDefault = true
    public private(set) var selectedPaneView: NSView?
    
    private var verticalPressure: Int = 0
    private var horizontalPressure: Int = 0
    
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
        
    // MARK: - Selection

    public override func mouseUp(theEvent: NSEvent) {
        let downPoint = self.convertPoint(theEvent.locationInWindow, fromView:nil)
        self.select(paneView: self.allSubPaneViews().filter({ NSPointInRect(downPoint, $0.frame) }).first)
        super.mouseUp(theEvent)
    }
    
    private func select(paneView pane: PaneView?) {
        self.selectedPaneView = pane
        for subPaneView in self.allSubPaneViews() { subPaneView.select(subPaneView == pane) }
    }
    
    // MARK: - Adding & Removing Subviews

    public func canAddSubview(vertically: Bool) -> Bool {
        guard self.delegate != nil, let delegate = self.delegate as! PressureSplitViewDelegate? else {
            return true
        }
        
        let viewCount = max(1, (vertically == true) ? self.horizontalPressure : self.verticalPressure)
        let minimumCurrentExtension = CGFloat(viewCount) * ((vertically == true) ? delegate.minimumWidth : delegate.minimumHeight)
        let minimumAdditionalExtension = (vertically == true) ? delegate.minimumWidth : delegate.minimumHeight;
        let currentExtension = (vertically == true) ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
        
        return (currentExtension - minimumCurrentExtension >= minimumAdditionalExtension);
    }

    override public func addSubview(view: NSView) {
        super.addSubview(view);
        if view.isKindOfClass(PaneView) {
            self.updatePressuresWithView(view, sign:1);
        }
    }

    override public func addSubview(view: NSView, positioned place: NSWindowOrderingMode, relativeTo otherView: NSView?) {
        super.addSubview(view, positioned: place, relativeTo: otherView)
        if view.isKindOfClass(PaneView) {
            self.updatePressuresWithView(view, sign: 1);
        }
    }
    
    override public func addArrangedSubview(view: NSView) {
        super.addArrangedSubview(view)
        if view.isKindOfClass(PaneView) {
            self.updatePressuresWithView(view, sign: 1)
        }
    }
    
    override public func insertArrangedSubview(view: NSView, atIndex index: Int) {
        super.insertArrangedSubview(view, atIndex: index)
        if view.isKindOfClass(PaneView) {
            self.updatePressuresWithView(view, sign: 1)
        }
    }
    
    private func updatePressuresWithView(view: NSView, sign: Int) {
        // I'm sure there must be something a lot simpler for this.
        if (self.vertical) {
            self.horizontalPressure += sign
            if view.isKindOfClass(NSSplitView) {
                let sv = view as! NSSplitView
                self.verticalPressure += sign*sv.subviews.count
            }
        }
        else {
            self.verticalPressure += sign
            if view.isKindOfClass(NSSplitView) {
                let sv = view as! NSSplitView
                self.horizontalPressure += sign*sv.subviews.count
            }
        }
    }
    
    override public func removeArrangedSubview(view: NSView) {
        super.removeArrangedSubview(view)
        self.updatePressuresWithView(view, sign: -1)
    }

    // MARK: - Close & Split

    func close(paneView pane: PaneView) {
        pane.removeFromSuperview()
    }
    
    func split(paneView pane: PaneView) {
        let mask = self.window?.styleMask;
        if (mask ==  NSFullScreenWindowMask || mask == NSFullSizeContentViewWindowMask) {
            NSBeep();
            return;
        }
        
        let theEvent = NSApp.currentEvent;
        let optionsKey = NSEventModifierFlags(rawValue: theEvent!.modifierFlags.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue)
        let vertical = (optionsKey == .AlternateKeyMask)
        
        if self.canAddSubview(vertical) == true {
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
                NSBeep();
            }
        }
    }
    
    private func showSplitSizeWarningAlert(paneView: PaneView, vertically: Bool) {
        guard self.delegate != nil, let delegate = self.delegate as! PressureSplitViewDelegate? else {
            NSBeep();
            return
        }
        
        let size = self.frame.size
        let maximumContentRect = self.window!.contentRectForFrameRect(self.window!.screen!.frame)
    
        let currentExtension = (vertical) ? size.width : size.height;
        let maximumExtension = (vertical) ? maximumContentRect.size.width : maximumContentRect.size.height;
        let minimumAdditionalExtension = (vertical) ? delegate.minimumWidth+5.0 : delegate.minimumHeight+5.0;
    
        let alert = NSAlert.alertForMinimumSplitAdditionalExtension(minimumAdditionalExtension,
                                                                    currentExtension: currentExtension,
                                                                    maximumExtension: maximumExtension,
                                                                    vertical: vertical)
    
        alert.beginSheetModalForWindow(self.window!, completionHandler: { (returnCode) in
            if alert.suppressionButton?.state == NSOnState {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setBool(false, forKey: PressureSplitViewSplitSizeWarningShowAgainKey)
            }
            
            if (returnCode == NSAlertSecondButtonReturn) {
                let deltaExtension = 2.0*minimumAdditionalExtension
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
                    self.splitPaneView(paneView, vertically: vertically)
                }
                self.window!.setFrame(newWindowFrame, display:true, animate:true)
            }
        })
    }

    private func splitPaneView(paneView: PaneView, vertically: Bool) {
        
        let parentSplitView = paneView.parentSplitView()
        guard parentSplitView == self else {
            fatalError("Parent SplitView of \(paneView) should be \(self), and it seems it is not.")
        }
        
        let newPaneView = PaneView.newPaneView()
        let newPaneViewIndex = self.indexOfPaneView(paneView)+1
        
        let newSplitView = PressureSplitView()
        newSplitView.delegate = self.delegate

        if self.vertical == vertically {
            // We are going into the same direction, just add a new pane.
            
            newSplitView.frame = self.frame
            self.superview?.addSubview(newSplitView)
            
            for view in self.allNonDividerSubviews() {
                view.removeFromSuperview()
                newSplitView.addSubview(view)
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
            
            newSplitView.adjustSubviews()
            newSplitView.setPosition(side/2.0, ofDividerAtIndex: 0)

            // This is a tricky workaround to force rearrangement of subviews...
            self.setPosition(1, ofDividerAtIndex: newPaneViewIndex)
        }
        
        newSplitView.window?.makeFirstResponder(newPaneView)
    }
    
    // MARK: - Helpers
    
    private func allNonDividerSubviews() -> [NSView] {
        // Some pane views can be splitviews themselves, if horizontal|vertical split has been
        // embedded inside a vertical|horizontal pane.
        return self.subviews.filter({ $0.isKindOfClass(PaneView) || $0.isKindOfClass(PressureSplitView) })
    }
    
    private func allSubPaneViews() -> [PaneView] {
        return self.subviews.filter({ $0.isKindOfClass(PaneView) }) as! [PaneView]
    }
    
    private func indexOfPaneView(paneView: PaneView) -> Int {
        let sortedSubviews = self.allNonDividerSubviews().sort( { (firstView, secondView) -> Bool in
            let v1 = (self.vertical) ? CGRectGetMinX(firstView.frame) : CGRectGetMinY(firstView.frame)
            let v2 = (self.vertical) ? CGRectGetMinX(secondView.frame) : CGRectGetMinY(secondView.frame)
            return v1 < v2
        })
        return sortedSubviews.indexOf(paneView)!
    }
}


private extension NSAlert {
    static func alertForMinimumSplitAdditionalExtension(minimumAdditionalExtension: CGFloat,
                                                        currentExtension: CGFloat,
                                                        maximumExtension: CGFloat,
                                                        vertical: Bool) -> NSAlert
    {
        let direction = (vertical) ? "horizontally" : "vertically"
        let extensionName = (vertical) ? "width" : "height"
        
        let informativeText = NSMutableString()
        informativeText.appendFormat(NSLocalizedString("A new pane requires a minimum of \(minimumAdditionalExtension) additional points \(direction).", comment: ""))
        informativeText.appendString(" ")
        informativeText.appendFormat(NSLocalizedString("The current view has a \(extensionName) of \(currentExtension) points.", comment: ""))
        
        informativeText.appendString(" ")
        informativeText.appendFormat(NSLocalizedString("And it can extends to a maximum of \(maximumExtension) points (accounting for window borders).", comment: ""))
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Not enough room to split.", comment: "")
        alert.informativeText = informativeText as String
        alert.showsSuppressionButton = true
        alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        
        if (currentExtension + minimumAdditionalExtension < maximumExtension) {
            alert.addButtonWithTitle(NSLocalizedString("Adjust window automatically", comment: ""))
        }
        
        return alert
    }
}
