//
//  DevicesPopover.swift
//  adbconnect
//
//  Created by Naman Dwivedi on 11/03/21.
//

import Foundation
import SwiftUI

class DevicesPopover: NSPopover {
    func update() {
        let contentView = ContentView()
        contentViewController = NSHostingController(rootView: contentView)
    }
}
