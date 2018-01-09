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

private func stringFrom(status: OSStatus) -> String {
    return stringFrom(fourCC: UInt32(bitPattern: status))
}

private func format(fourCC: UInt32) -> String
{
    return "'\(stringFrom(fourCC: fourCC))' (\(fourCC))"
}

private func format(status: OSStatus) -> String {
    return "'\(stringFrom(status: status))' (\(status))"
}

private func format(address: AudioObjectPropertyAddress) -> String {
    return "{" +
        "selector: \(format(fourCC: address.mSelector))" +
        ", " +
        "scope: \(format(fourCC: address.mScope))" +
        ", " +
        "element: \(format(fourCC: address.mElement))" +
    "}"
}


enum AudioDeviceType {
    case Unset
    case Invalid
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
            let icon = iconNonTemplate
            icon.isTemplate = true
            return icon
        }
    }

    private var iconNonTemplate: NSImage {
        get {
            switch self {
            case .Unset:
                fatalError("Unset display names shouldn't happen")
            case .Invalid:
                return NSImage(named: NSImage.Name(rawValue: "StatusOutputUnknown"))!
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
            case .Unset:
                fatalError("Unset display names shouldn't happen")
            case .Invalid:
                return "invalid device"
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

enum SoundDeviceError: Error {
    case statusFailure(OSStatus)
}

class SoundDeviceWatcher {
    private var defaultOutputDevice: AudioDeviceID = 0

    private var currentDevice = AudioDeviceType.Unset
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
        removeOutputSpecificListeners()

        do {
            let newOutputDevice =  try numericPropertyValue(forDevice: UInt32(kAudioObjectSystemObject),
                                                            address: addressDefaultOutputDevice)
            NSLog("The default output device changed from \(defaultOutputDevice) to \(newOutputDevice)")
            defaultOutputDevice = newOutputDevice


            addListener(deviceID: defaultOutputDevice,
                        address: addressOutputDataSource,
                        block: outputDataSourceDidChangeHackBlock!)

            // I don't think the transport type can change for the same device, but let's watch for changes anyway.
            addListener(deviceID: defaultOutputDevice,
                        address: addressTransportType,
                        block:  transportTypeDidChangeHackBlock!)
        } catch SoundDeviceError.statusFailure(let status) {
            NSLog(
                "Failed to get the default audio device (the last value is \(defaultOutputDevice)): " +
                "\(format(status: status))")
        } catch {
            fatalError()
        }

        updateAudioDeviceType()
    }

    private func outputDataSourceDidChange(numberAddresses: UInt32,
                                           addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        do {
            let s = format(fourCC: try dataSourceType())
            NSLog("The data source type changed to \(s)")
        } catch SoundDeviceError.statusFailure(let status) {
            NSLog("Cannot get data source: \(format(status: status))")
        } catch {
            fatalError()
        }

        updateAudioDeviceType()
    }

    private func transportTypeDidChange(numberAddresses: UInt32,
                                        addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        do {
            let s = format(fourCC: try transportType())
            NSLog("The audio transport type changed to \(s)")
        } catch SoundDeviceError.statusFailure(let status) {
            NSLog("Cannot get transport type: \(format(status: status))")
        } catch {
            fatalError()
        }
        updateAudioDeviceType()
    }

    func startListening(watcherCallback: @escaping (AudioDeviceType) -> ()) {
        // Workaround for Swift generating a different block pointer every time a closure/method is passed to a
        // CoreAudio function. See HackAudioBlock's documentation for details.
        defaultOutputDidChangeHackBlock = HackAudioBlock(block: defaultOutputDidChange)
        outputDataSourceDidChangeHackBlock = HackAudioBlock(block: outputDataSourceDidChange)
        transportTypeDidChangeHackBlock = HackAudioBlock(block: transportTypeDidChange)

        addListener(deviceID: UInt32(kAudioObjectSystemObject),
                    address: addressDefaultOutputDevice,
                    block: defaultOutputDidChangeHackBlock!)

        self.watcherCallback = watcherCallback

        var address = addressOutputDataSource
        defaultOutputDidChange(numberAddresses: 1,
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
        watcherCallback = nil

        removeOutputSpecificListeners()
        removeListener(deviceID: UInt32(kAudioObjectSystemObject),
                       address: addressDefaultOutputDevice,
                       block: defaultOutputDidChangeHackBlock!)

        defaultOutputDevice = 0

        defaultOutputDidChangeHackBlock = nil
        outputDataSourceDidChangeHackBlock = nil
        transportTypeDidChangeHackBlock = nil
    }

    private func removeOutputSpecificListeners()
    {
        if defaultOutputDevice == 0 {
            return
        }

        removeListener(deviceID: defaultOutputDevice,
                       address: addressOutputDataSource,
                       block: outputDataSourceDidChangeHackBlock!)
        removeListener(deviceID: defaultOutputDevice,
                       address: addressTransportType,
                       block: transportTypeDidChangeHackBlock!)
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
        let newType: AudioDeviceType
        do {
            newType = AudioDeviceType(transportType: try transportType(),
                                      dataSourceType: try dataSourceType())
        } catch SoundDeviceError.statusFailure(let status) {
            NSLog("Invalid transport or data source type: \(format(status: status))")
            newType = AudioDeviceType.Invalid
        } catch {
            fatalError()
        }

        if newType != currentDevice {
            NSLog("The current audio source changed from \(currentDevice) to \(newType)")
            currentDevice = newType

            if let callback = watcherCallback {
                callback(currentDevice)
            }
        }
    }

    private func numericPropertyValue(forDevice deviceID: AudioDeviceID,
                                      address: AudioObjectPropertyAddress) throws -> UInt32 {
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
            NSLog("ERROR! Failed to get property for device \(deviceID) and address \(format(address: address)): " +
                "\(format(status: status))")
            throw SoundDeviceError.statusFailure(status)
        }

        return prop;
    }

    private func dataSourceType() throws -> UInt32 {
        return try numericPropertyValue(forDevice: defaultOutputDevice,
                                        address: addressOutputDataSource)
    }

    private func transportType() throws -> UInt32 {
        return try numericPropertyValue(forDevice: defaultOutputDevice,
                                        address: addressTransportType)
    }
}
