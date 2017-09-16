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
    let statuItemController = StatusItemController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statuItemController.setUpStatusItem()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.statuItemController.tearDownStatusItem()
    }
}
