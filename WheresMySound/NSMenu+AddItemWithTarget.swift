//
//  NSMenu+AddItemWithTarget.swift
//  WheresMySound
//
//  Created by Marco Barisione on 23/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

import Cocoa

extension NSMenu {

    @discardableResult
    func addItem(withTitle string: String,
                 target: AnyObject?,
                 action selector: Selector?,
                 keyEquivalent charCode: String) -> NSMenuItem {
        let item = addItem(withTitle: string,
                           action: selector,
                           keyEquivalent: charCode)
        item.target = target
        return item
    }
}
