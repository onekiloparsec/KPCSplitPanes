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
        while view != nil && view?.isKind(of: PressureSplitView.self) == false {
            view = view!.superview
        }
        return view as! PressureSplitView?
    }
}

extension NSEvent {
    func hasAltKeyPressed() -> Bool {
        return NSEventModifierFlags(rawValue: self.modifierFlags.rawValue & NSEventModifierFlags.option.rawValue) == .option
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
        alert.addButton(withTitle: NSLocalizedString("Do nothing", comment: ""))
     
        let direction = (vertical) ? "horizontally" : "vertically"
        let informativeText = NSMutableString()
        informativeText.appendFormat(NSLocalizedString("A new pane requires a minimum of \(additionalExtension) additional points \(direction).", comment: "") as NSString)
        informativeText.append(" ")
        informativeText.appendFormat(NSLocalizedString("Window resize is possible: there are \(maximumExtent-currentExtent) points available in this direction on this screen (accounting for window borders).", comment: "") as NSString)
        alert.informativeText = informativeText as String
        
        if (currentExtent + additionalExtension < maximumExtent) {
            alert.addButton(withTitle: NSLocalizedString("Adjust window size automatically", comment: ""))
        }
        
        return alert
    }
    
    static func alertForLastPane() -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = NSLocalizedString("Be careful!", comment: "")
        alert.informativeText = NSLocalizedString("This is the last pane of the split view. Do you confirm you want to close it?", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("I confirm, close it.", comment: ""))
        return alert
    }
}

extension IndexPath {
    public func stringValue() -> String {
        let reprensentation = NSMutableString()
        reprensentation.appendFormat("%ld", self[0]);
        
        for position in 1..<(self as NSIndexPath).length {
            reprensentation.appendFormat(".%ld", self[position]);
        }
        
        return reprensentation.copy() as! String;
    }
}
