//
//  AppDelegate.swift
//  adbconnect
//
//  Created by Naman Dwivedi on 10/03/21.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: DevicesPopover!
    var statusBarItem: NSStatusItem!

    func applicationDidFinishLaunching(_: Notification) {
        // Create the popover
        let popover = DevicesPopover()
        popover.contentSize = NSSize(width: 300, height: 250)
        popover.behavior = .transient
        self.popover = popover

        // Create the status item
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = statusBarItem.button {
            button.image = NSImage(named: "Icon")
            button.action = #selector(togglePopover(_:))
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                popover.update()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    func applicationWillResignActive(_: Notification) {
        popover.performClose(nil)
    }
}
