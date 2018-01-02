//
//  PreferencesViewController.swift
//  WheresMySound
//
//  Created by Marco Barisione on 01/01/2018.
//  Copyright © 2018 Marco Barisione. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    // This is only needed to notice when the window gets closed.
    @objc private class WindowDelegate: NSObject, NSWindowDelegate {
        func windowWillClose(_ notification: Notification) {
            PreferencesViewController.window = nil
        }
    }

    private static var window: NSWindow? = nil
    private static let windowDelegate = WindowDelegate()

    @IBOutlet private weak var autoStartCheckBox: NSButton!

    private var autoStartController: AutoStartController?

    static func showWindow(autoStartController: AutoStartController) {
        if window == nil {
            let controller = newController()
            controller.autoStartController = autoStartController

            window = NSWindow(contentViewController: controller)
            window!.delegate = windowDelegate
            window!.title = "Preferences"
            window!.styleMask.remove(NSWindow.StyleMask.resizable)
            window!.styleMask.remove(NSWindow.StyleMask.miniaturizable)
        }

        // Not just orderFront as we are not a normal app with windows, so the window would end up in
        // background.
        window!.orderFrontRegardless()
        window!.makeKey()
    }

    private static func newController() -> PreferencesViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let id = NSStoryboard.SceneIdentifier(rawValue: "PreferencesViewController")
        let controller = storyboard.instantiateController(withIdentifier: id) as! PreferencesViewController

        return controller
    }

    @objc var autoStart: Bool {
        get {
            return autoStartController!.isEnabled
        }

        set(v) {
            autoStartController!.isEnabled = v
        }
    }
}
