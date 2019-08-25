//
//  MaiScreenSaverWindow.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Cocoa

final class MaiScreenSaverWindow: NSWindow {
    
    convenience init(screen: NSScreen) {
        let size = screen.frame.size
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)

        self.backgroundColor = NSColor(calibratedRed: 0.129, green: 0.118, blue: 0.333, alpha: 1)
        // Do not use `CGWindowLevelKey.desktopWindow.rawValue`
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = true
        self.orderFront(nil)

        if let contentView = self.contentView, let saverView = MaiScreenSaverView(frame: contentView.bounds, isPreview: false) {
            saverView.autoresizingMask = [.width, .height]
            contentView.addSubview(saverView)
        }
    }
}
