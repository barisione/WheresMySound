//
//  StatusItemController.swift
//  WheresMySound
//
//  Created by Marco Barisione on 16/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

import Cocoa

class StatusItemController {
    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    var currentDeviceMenuItem: NSMenuItem?
    var watcher = SoundDeviceWatcher()
    var iconUpdateTimer: Timer?

    #if DEBUG
    var cyclingIconsTimer: Timer?
    #endif

    func setUpStatusItem() {
        self.buildMenu()

        self.watcher.startListening(watcherCallback: self.outputSourceChanged)
    }

    func tearDownStatusItem() {
        self.watcher.stopListening()
        self.stopIconAnimation()

        #if DEBUG
            self.cyclingIconsTimer?.invalidate()
        #endif
    }

    private func buildMenu() {
        let menu = NSMenu()

        self.currentDeviceMenuItem = NSMenuItem(title: "",
                                                action: nil,
                                                keyEquivalent: "")
        menu.addItem(self.currentDeviceMenuItem!)

        #if DEBUG
            menu.addItem(NSMenuItem(title: "DEBUG: Start cycling icons",
                                    action: #selector(StatusItemController.startCyclingIcons(_:)),
                                    keyEquivalent: "c"))
        #endif

        menu.addItem(NSMenuItem(title: "Quit Where's My Sound",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private var sourceHasChangedBefore = false

    private func outputSourceChanged(deviceType: AudioDeviceType) {
        // We don't animate the initial style after starting the program.
        self.updateOutputSourceIcon(deviceType: deviceType, animate: self.sourceHasChangedBefore)
        self.sourceHasChangedBefore = true
    }

    private func updateOutputSourceIcon(deviceType: AudioDeviceType,
                                        animate: Bool) {
        print("Sound coming from \(deviceType)")

        self.currentDeviceMenuItem?.title = "Default output: \(deviceType.displayName)"

        if animate {
            self.startIconAnimation(deviceType: deviceType)
        } else {
            self.setFinalIcon(deviceType: deviceType)
        }
    }

    private func setFinalIcon(deviceType: AudioDeviceType) {
        self.statusItem.button?.image = deviceType.icon
    }

    private func stopIconAnimation() {
        self.iconUpdateTimer?.invalidate()
        self.iconUpdateTimer = nil
    }

    private func startIconAnimation(deviceType: AudioDeviceType) {
        self.stopIconAnimation()

        var currentIteration = 0
        let template = deviceType.icon

        // We create several tintend images to display an animation.
        // The gradient gives us the steps in colour we need.
        let startColor = self.systemIsUsingDarkTheme() ? NSColor.white : NSColor.black
        let gradient = NSGradient(starting:startColor,
                                  ending:NSColor(red:0, green:0.75, blue:1, alpha:1))!

        var allColoredIcons = [NSImage]()
        // First generate a few steps.
        for step in stride(from: 0.0, through: 1.0, by: 0.05) {
            let color = gradient.interpolatedColor(atLocation: CGFloat(step))
            allColoredIcons.append(template.tintedTemplate(color: color))
        }
        // Then make the last step persist a bit longer (it just looks nicer).
        let lastStep = allColoredIcons[allColoredIcons.count - 1]
        for _ in 0..<5 {
            allColoredIcons.append(lastStep)
        }
        // And finally duplicate the same images but in reverse order (to show the colour going back).
        for i in stride(from: allColoredIcons.count - 1, through: 0, by: -1) {
            allColoredIcons.append(allColoredIcons[i])
        }

        self.iconUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {
            (_) in

            let index = currentIteration % allColoredIcons.count
            currentIteration += 1

            if index == 0 && currentIteration / allColoredIcons.count >= 4 {
                // Animated for long enough.
                self.stopIconAnimation()
                self.setFinalIcon(deviceType: deviceType)
                return
            }

            self.statusItem.button?.image = allColoredIcons[index]
        }
    }

    private func systemIsUsingDarkTheme() -> Bool {
        let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        if let style = style, style == "Dark" {
            return true
        } else {
            return false
        }
    }

    #if DEBUG
    @objc private func startCyclingIcons(_ sender: Any?) {
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
            self.updateOutputSourceIcon(deviceType: allTypes[currentIndex], animate: false)
            currentIndex = (currentIndex + 1) % allTypes.count
        }

        self.cyclingIconsTimer!.fire()
    }
    #endif // DEBUG
}
