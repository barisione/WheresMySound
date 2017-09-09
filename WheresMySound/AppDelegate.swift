//
//  AppDelegate.swift
//  WheresMySound
//
//  Created by Marco Barisione on 09/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = #imageLiteral(resourceName: "StatusOutputHeadphones")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }


}

