//
//  MaiScreenSaverWindow.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Cocoa

final class MaiScreenSaverWindow: NSWindow {

    private var screenSaverView: MaiScreenSaverView?

    convenience init(screen: NSScreen) {
        let size = screen.frame.size
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)

        // Do not use `CGWindowLevelKey.desktopWindow.rawValue`
        backgroundColor = NSColor(calibratedRed: 0.129, green: 0.118, blue: 0.333, alpha: 1)
        level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        ignoresMouseEvents = true
        orderFront(nil)


        if let contentView = contentView {
            screenSaverView = MaiScreenSaverView(frame: contentView.bounds, isPreview: false)
            screenSaverView!.autoresizingMask = [.width, .height]
            contentView.addSubview(screenSaverView!)
        }
    }
}
