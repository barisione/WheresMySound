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
    var currentDeviceMenuItem: NSMenuItem?
    var watcher = SoundDeviceWatcher()

    #if DEBUG
    var cyclingIconsTimer: Timer?
    #endif

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.buildMenu()

        self.watcher.startListening(watcherCallback: self.outputSourceChanged)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.watcher.stopListening()

        #if DEBUG
            self.cyclingIconsTimer?.invalidate()
        #endif
    }

    func buildMenu() {
        let menu = NSMenu()

        self.currentDeviceMenuItem = NSMenuItem(title: "",
                                                action: nil,
                                                keyEquivalent: "")
        menu.addItem(self.currentDeviceMenuItem!)

        #if DEBUG
            menu.addItem(NSMenuItem(title: "DEBUG: Start cycling icons",
                                    action: #selector(AppDelegate.startCyclingIcons(_:)),
                                    keyEquivalent: "c"))
        #endif

        menu.addItem(NSMenuItem(title: "Quit Where's My Sound",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func outputSourceChanged(deviceType: AudioDeviceType) {
        print("Sound coming from \(deviceType)")
        statusItem.button?.image = deviceType.icon
        self.currentDeviceMenuItem?.title = "Default output: \(deviceType.displayName)"
    }

    #if DEBUG
    func startCyclingIcons(_ sender: Any?) {
        if self.cyclingIconsTimer != nil {
            return;
        }

        let allTypes: [AudioDeviceType] = [
            .Unknown,
            .InternalSpeaker,
            .ExternalSpeaker,
            .Headphones,
            .Bluetooth,
            .USB,
            .HDMI,
            .DisplayPort,
            .FireWire,
            .Thunderbolt,
            .Ethernet,
            .PCI,
            .AirPlay,
            .Virtual,
            .Aggregate,
            ]

        var currentIndex = 0;
        self.cyclingIconsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) {
            (_) in
            self.outputSourceChanged(deviceType: allTypes[currentIndex])
            currentIndex = (currentIndex + 1) % allTypes.count
        }

        self.cyclingIconsTimer!.fire()
    }
    #endif // DEBUG
}
