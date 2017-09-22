//
//  SoundDeviceWatcher.swift
//  WheresMySound
//
//  Created by Marco Barisione on 10/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

import Foundation
import Cocoa
import CoreAudio

private func stringFrom(fourCC: UInt32) -> String {
    func charByte(at byteIndex: UInt32) -> String {
        let scalar = UnicodeScalar((fourCC >> (byteIndex * 8)) & 255)!
        if scalar.value == 0 {
            return ""
        }
        return String(scalar)
    }

    // This only works for little endian.
    return charByte(at: 3) + charByte(at: 2) + charByte(at: 1) + charByte(at: 0)
}

enum AudioDeviceType {
    case Unknown
    case InternalSpeaker
    case ExternalSpeaker
    case Headphones
    case Bluetooth
    case USB
    case HDMI
    case DisplayPort
    case FireWire
    case Thunderbolt
    case Ethernet
    case PCI
    case AirPlay
    case Virtual
    case Aggregate

    static private func typeFrom(dataSource: UInt32) -> AudioDeviceType {
        switch stringFrom(fourCC: dataSource)  {
        case "hdpn": return .Headphones
        case "ispk": return .InternalSpeaker
        case "espk": return .ExternalSpeaker
        default: return .Unknown
        }
    }

    static private func typeFrom(transportType: UInt32) -> AudioDeviceType {
        switch transportType {
        case kAudioDeviceTransportTypeBuiltIn: return .Unknown
        case kAudioDeviceTransportTypeAggregate: return .Aggregate
        case kAudioDeviceTransportTypeVirtual: return .Virtual
        case kAudioDeviceTransportTypePCI: return .PCI
        case kAudioDeviceTransportTypeUSB: return .USB
        case kAudioDeviceTransportTypeFireWire: return .FireWire
        case kAudioDeviceTransportTypeBluetooth: return .Bluetooth
        case kAudioDeviceTransportTypeBluetoothLE: return .Bluetooth
        case kAudioDeviceTransportTypeHDMI: return .HDMI
        case kAudioDeviceTransportTypeDisplayPort: return .DisplayPort
        case kAudioDeviceTransportTypeAirPlay: return .AirPlay
        case kAudioDeviceTransportTypeAVB: return .Ethernet
        case kAudioDeviceTransportTypeThunderbolt: return .Thunderbolt
        default: return .Unknown
        }
    }

    init(transportType: UInt32, dataSourceType: UInt32) {
        self = AudioDeviceType.typeFrom(dataSource: dataSourceType)
        if self != .Unknown {
            return
        }

        self = type(of: self).typeFrom(transportType: transportType)
    }

    var icon: NSImage {
        get {
            let icon = self.iconNonTemplate
            icon.isTemplate = true
            return icon
        }
    }

    private var iconNonTemplate: NSImage {
        get {
            switch self {
            case .Unknown:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputUnknown"))!
            case .InternalSpeaker:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputInternalSpeaker"))!
            case .ExternalSpeaker:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputExternalSpeaker"))!
            case .Headphones:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputHeadphones"))!
            case .Bluetooth:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputBluetooth"))!
            case .USB:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputUSB"))!
            case .HDMI:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputHDMI"))!
            case .DisplayPort:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputDisplayPort"))!
            case .FireWire:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputFireWire"))!
            case .Thunderbolt:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputThunderbolt"))!
            case .Ethernet:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputEthernet"))!
            case .PCI:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputExternalSpeaker"))!
            case .AirPlay:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputAirplay"))!
            case .Virtual:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputVirtual"))!
            case .Aggregate:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputUnknown"))!
            }
        }
    }

    var displayName: String {
        get {
            switch self {
            case .Unknown:
                return "unknown device"
            case .InternalSpeaker:
                return "internal speaker"
            case .ExternalSpeaker:
                return "external speaker"
            case .Headphones:
                return "headphones"
            case .Bluetooth:
                return "Bluetooth"
            case .USB:
                return "USB"
            case .HDMI:
                return "HDMI"
            case .DisplayPort:
                return "DisplayPort"
            case .FireWire:
                return "FireWire"
            case .Thunderbolt:
                return "Thunderbolt"
            case .Ethernet:
                return "Ethernet (AVB)"
            case .PCI:
                return "external speaker (PCI)"
            case .AirPlay:
                return "AirPlay"
            case .Virtual:
                return "virtual device"
            case .Aggregate:
                return "aggregate device"
            }
        }
    }
}

class SoundDeviceWatcher {
    private var defaultOutputDevice: AudioDeviceID = 0

    private var currentDevice = AudioDeviceType.Unknown
    private var watcherCallback: ((AudioDeviceType) -> ())?

    private let addressDefaultOutputDevice = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster)
    private let addressOutputDataSource = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDataSource,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMaster)
    private let addressTransportType = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyTransportType,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster)

    private var defaultOutputDidChangeHackBlock: HackAudioBlock?
    private var outputDataSourceDidChangeHackBlock: HackAudioBlock?
    private var transportTypeDidChangeHackBlock: HackAudioBlock?

    private func defaultOutputDidChange(numberAddresses: UInt32,
                                        addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        self.removeOutputSpecificListeners()

        let newOutputDevice =  self.numericPropertyValue(forDevice: UInt32(kAudioObjectSystemObject),
                                                         address: self.addressDefaultOutputDevice)
        NSLog("The default output device changed from \(self.defaultOutputDevice) to \(newOutputDevice)")
        self.defaultOutputDevice = newOutputDevice

        self.addListener(deviceID: self.defaultOutputDevice,
                         address: self.addressOutputDataSource,
                         block: self.outputDataSourceDidChangeHackBlock!)

        // I don't think the transport type can change for the same device, but let's watch for changes anyway.
        self.addListener(deviceID: self.defaultOutputDevice,
                         address: self.addressTransportType,
                         block:  self.transportTypeDidChangeHackBlock!)

        self.updateAudioDeviceType()
    }

    private static func format(fourCC: UInt32) -> String
    {
        let fourCCString = stringFrom(fourCC: fourCC)
        return "'\(fourCCString)' (\(fourCC))"
    }

    private func outputDataSourceDidChange(numberAddresses: UInt32,
                                           addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        let s = SoundDeviceWatcher.format(fourCC: self.dataSourceType())
        NSLog("The data source type changed to \(s)")
        self.updateAudioDeviceType()
    }

    private func transportTypeDidChange(numberAddresses: UInt32,
                                        addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        let s = SoundDeviceWatcher.format(fourCC: self.transportType())
        NSLog("The audio transport type changed to \(s)")
        self.updateAudioDeviceType()
    }

    func startListening(watcherCallback: @escaping (AudioDeviceType) -> ()) {
        // Workaround for Swift generating a different block pointer every time a closure/method is passed to a
        // CoreAudio function. See HackAudioBlock's documentation for details.
        self.defaultOutputDidChangeHackBlock = HackAudioBlock(block: self.defaultOutputDidChange)
        self.outputDataSourceDidChangeHackBlock = HackAudioBlock(block: self.outputDataSourceDidChange)
        self.transportTypeDidChangeHackBlock = HackAudioBlock(block: self.transportTypeDidChange)

        self.addListener(deviceID: UInt32(kAudioObjectSystemObject),
                         address: self.addressDefaultOutputDevice,
                         block: self.defaultOutputDidChangeHackBlock!)

        self.watcherCallback = watcherCallback

        var address = self.addressOutputDataSource
        self.defaultOutputDidChange(numberAddresses: 1,
                                    addresses: &address)
    }

    private func addListener(deviceID: AudioDeviceID,
                             address: AudioObjectPropertyAddress,
                             block: HackAudioBlock)
    {
        var address = address
        hackAudioObjectAddPropertyListenerBlock(deviceID,
                                                &address,
                                                DispatchQueue.main,
                                                block)
    }

    func stopListening() {
        self.watcherCallback = nil

        self.removeOutputSpecificListeners()
        self.removeListener(deviceID: UInt32(kAudioObjectSystemObject),
                            address: self.addressDefaultOutputDevice,
                            block: self.defaultOutputDidChangeHackBlock!)

        self.defaultOutputDevice = 0

        self.defaultOutputDidChangeHackBlock = nil
        self.outputDataSourceDidChangeHackBlock = nil
        self.transportTypeDidChangeHackBlock = nil
    }

    private func removeOutputSpecificListeners()
    {
        if self.defaultOutputDevice == 0 {
            return
        }

        self.removeListener(deviceID: self.defaultOutputDevice,
                            address: self.addressOutputDataSource,
                            block: self.outputDataSourceDidChangeHackBlock!)
        self.removeListener(deviceID: self.defaultOutputDevice,
                            address: self.addressTransportType,
                            block: self.transportTypeDidChangeHackBlock!)
    }

    private func removeListener(deviceID: AudioDeviceID,
                                address: AudioObjectPropertyAddress,
                                block: HackAudioBlock)
    {
        var address = address
        hackAudioObjectRemovePropertyListenerBlock(deviceID,
                                                   &address,
                                                   DispatchQueue.main,
                                                   block)
    }

    private func updateAudioDeviceType() {
        let newType = AudioDeviceType(transportType: self.transportType(), dataSourceType: self.dataSourceType())

        if newType != self.currentDevice {
            NSLog("The current audio source changed from \(self.currentDevice) to \(newType)")
            self.currentDevice = newType

            if let callback = self.watcherCallback {
                callback(self.currentDevice)
            }
        }
    }

    private func numericPropertyValue(forDevice deviceID: AudioDeviceID,
                                      address: AudioObjectPropertyAddress) -> UInt32 {
        var address = address
        var prop: UInt32 = 0
        var propSize = UInt32(MemoryLayout.size(ofValue:prop))

        let status = AudioObjectGetPropertyData(deviceID,
                                                &address,
                                                0,
                                                nil,
                                                &propSize,
                                                &prop);
        if status != noErr {
            return 0;
        }

        return prop;
    }

    private func dataSourceType() -> UInt32 {
        return self.numericPropertyValue(forDevice: self.defaultOutputDevice,
                                         address: self.addressOutputDataSource)
    }

    private func transportType() -> UInt32 {
        return self.numericPropertyValue(forDevice: self.defaultOutputDevice,
                                         address: self.addressTransportType)
    }
}
