//
//  AutoStartController.swift
//  WheresMySound
//
//  Created by Marco Barisione on 19/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

import Foundation
import ServiceManagement

enum AutoStartStatus: String {
    case enabled
    case disabledByUser
    case notEnabledYet

    var isEnabled: Bool {
        get {
            return self == .enabled
        }
    }
}

class AutoStartController {
    private let url: URL
    private let defaults: UserDefaults

    init(url: URL, defaults: UserDefaults) {
        self.url = url
        self.defaults = defaults

        // If the user has made a choice, make sure that the system configuration corresponds to that.
        if storedValue != .notEnabledYet {
            updateSystemAutoStart()
        }
    }

    var storedValue: AutoStartStatus {
        get {
            let valueString = defaults.string(forKey: "autoStart") ?? ""
            return AutoStartStatus(rawValue: valueString) ?? .notEnabledYet
        }
    }

    var isEnabled: Bool {
        get {
            return storedValue.isEnabled
        }

        set(value) {
            let storedValue = value ? AutoStartStatus.enabled : .disabledByUser
            defaults.set(storedValue.rawValue, forKey: "autoStart")
            updateSystemAutoStart()
        }
    }

    private func updateSystemAutoStart() {
        let autoStart = storedValue.isEnabled
        let helperID = Bundle.main.bundleIdentifier! + "Helper"
        let set = SMLoginItemSetEnabled(helperID as CFString, autoStart)
        if (!set) {
            NSLog("Cannot \(autoStart ? "enable" : "disable") the login item.");
        }
    }
}
