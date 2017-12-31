//
//  HelpPopover.swift
//  WheresMySound
//
//  Created by Marco Barisione on 25/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

import Cocoa
import AVKit

class HelpPopoverViewController: NSViewController {
    @IBOutlet private weak var playerView: AVPlayerView!
    private var looper: AVPlayerLooper? = nil
    private var onOKClicked: (() -> Void)?

    static func newController(onOKClicked: @escaping () -> Void) -> HelpPopoverViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let id = NSStoryboard.SceneIdentifier(rawValue: "HelpPopoverViewController")
        let controller = storyboard.instantiateController(withIdentifier: id) as! HelpPopoverViewController

        controller.onOKClicked = onOKClicked

        return controller
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        let videoURL = Bundle.main.url(forResource: "HowToMoveIcon",
                                       withExtension: "mp4")
        let player = AVQueuePlayer(url: videoURL!)
        self.playerView.player = player
        self.looper = AVPlayerLooper(player: player,
                                     templateItem: player.currentItem!)
        player.play()
    }

    @IBAction func okClicked(_ sender: Any) {
        self.onOKClicked?()
    }
}

class HelpPopoverManager {
    private static let popoverAlreadyDismissedKey = "popoverAlreadyDismissed"

    static func maybeShow(forView view: NSView?) {
        if !UserDefaults.standard.bool(forKey: HelpPopoverManager.popoverAlreadyDismissedKey) {
            self.show(forView: view)
        }
    }

    static func show(forView view: NSView?) {
        guard let view = view else { return }

        HelpPopoverManager.newPopover().show(relativeTo: view.bounds,
                                             of: view,
                                             preferredEdge: NSRectEdge.minY)
    }

    static private func newPopover() -> NSPopover {
        let popover = NSPopover()
        popover.contentViewController = HelpPopoverViewController.newController {
            popover.close()
            UserDefaults.standard.set(true, forKey: HelpPopoverManager.popoverAlreadyDismissedKey)
        }
        return popover;
    }
}
