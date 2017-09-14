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

        #if DEBUG
            menu.addItem(NSMenuItem(title: "DEBUG: Start cycling icons",
                                    action: #selector(AppDelegate.startCyclingIcons(_:)),
                                    keyEquivalent: "c"))
            menu.addItem(NSMenuItem.separator())
        #endif

        menu.addItem(NSMenuItem(title: "Quit Where's My Sound",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func outputSourceChanged(deviceType: AudioDeviceType) {
        print("Sound coming from \(deviceType)")
        statusItem.button?.image = deviceType.icon
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

        var allIcons = [(AudioDeviceType, NSImage)]()
        for type in allTypes {
            allIcons.append((type, type.icon))
        }

        var currentIndex = 0;
        self.cyclingIconsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) {
            (_) in
            guard let button = self.statusItem.button else { return }
            let (type, image) = allIcons[currentIndex]
            print("DEBUG: Setting icon for \(type)")
            button.image = image
            currentIndex = (currentIndex + 1) % allIcons.count
        }

        self.cyclingIconsTimer!.fire()
    }
    #endif // DEBUG
}
