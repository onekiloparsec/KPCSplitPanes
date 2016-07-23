//
//  Helpers.swift
//  KPCSplitPanes
//
//  Created by Cédric Foellmi on 04/06/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Foundation
import AppKit

extension NSView {    
    func parentSplitView() -> PressureSplitView? {
        var view: NSView? = self.superview
        while view != nil && view?.isKindOfClass(PressureSplitView) == false {
            view = view!.superview
        }
        return view as! PressureSplitView?
    }
}

extension NSEvent {
    func hasAltKeyPressed() -> Bool {
        let optionsKey = NSEventModifierFlags(rawValue: self.modifierFlags.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue)
        return (optionsKey == .AlternateKeyMask)
    }
}

// MARK: Alert

extension NSAlert {
    static func alert(forMinimumAdditionalExtension additionalExtension: CGFloat,
                                                    currentExtent: CGFloat,
                                                    maximumExtent: CGFloat,
                                                    vertical: Bool) -> NSAlert
    {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Not enough room to split internally", comment: "")
        alert.showsSuppressionButton = true
        alert.addButtonWithTitle(NSLocalizedString("Do nothing", comment: ""))
     
        let direction = (vertical) ? "horizontally" : "vertically"
        let informativeText = NSMutableString()
        informativeText.appendFormat(NSLocalizedString("A new pane requires a minimum of \(additionalExtension) additional points \(direction).", comment: ""))
        informativeText.appendString(" ")
        informativeText.appendFormat(NSLocalizedString("Window resize is possible: there are \(maximumExtent-currentExtent) points available in this direction on this screen (accounting for window borders).", comment: ""))
        alert.informativeText = informativeText as String
        
        if (currentExtent + additionalExtension < maximumExtent) {
            alert.addButtonWithTitle(NSLocalizedString("Adjust window size automatically", comment: ""))
        }
        
        return alert
    }
    
    static func alertForLastPane() -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .WarningAlertStyle
        alert.messageText = NSLocalizedString("Be careful!", comment: "")
        alert.informativeText = NSLocalizedString("This is the last pane of the split view. Do you confirm you want to close it?", comment: "")
        alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
        alert.addButtonWithTitle(NSLocalizedString("I confirm, close it.", comment: ""))
        return alert
    }
}

extension NSIndexPath {
    public func stringValue() -> String {
        let reprensentation = NSMutableString()
        reprensentation.appendFormat("%ld", self.indexAtPosition(0));
        
        for position in 1..<self.length {
            reprensentation.appendFormat(".%ld", self.indexAtPosition(position));
        }
        
        return reprensentation.copy() as! String;
    }
}