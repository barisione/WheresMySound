//
//  NSImage+Tinting.swift
//  WheresMySound
//
//  Created by Marco Barisione on 16/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

import Cocoa

extension NSImage {
    func tintedTemplate(color: NSColor) -> NSImage {
        let tinted = copy() as! NSImage
        tinted.isTemplate = false
        tinted.lockFocus()
        color.set()
        let rect = NSMakeRect(0, 0, size.width, size.height)
        rect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        return tinted
    }
}
