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
    var watcher = SoundDeviceWatcher()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.buildMenu()

        self.watcher.startListening(watcherCallback: self.outputSourceChanged)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.watcher.stopListening()
    }

    func buildMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Where's My Sound",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func outputSourceChanged(deviceType: AudioDeviceType) {
        print("Sound coming from \(deviceType)")
        statusItem.button?.image = deviceType.icon
    }
}
