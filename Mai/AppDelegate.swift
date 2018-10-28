//
//  AppDelegate.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Cocoa
import RxSwift
import ScreenSaver

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private var windows: [MaiScreenSaverWindow] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusItem()
        reloadWindows()

        VideoManager.shared.fetchIfPossible()
    }

    var disposeBag = DisposeBag()

    func applicationWillTerminate(_ notification: Notification) {
    }

    func reloadWindows() {
        windows.forEach { $0.close() }
        windows = NSScreen.screens.map { windowWithSaverView(on: $0) }
    }

    func windowWithSaverView(on screen: NSScreen) -> MaiScreenSaverWindow {
        return MaiScreenSaverWindow(screen: screen)
    }
}

// MARK: NSMenu
extension AppDelegate {

    func setupStatusItem() {
        statusItem.button?.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "About", action: #selector(AppDelegate.aboutDidtap(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(AppDelegate.checkForUpdatesDidTap(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let shadow = NSMenuItem(title: "Shadow", action: #selector(AppDelegate.shadowDidTap(_:)), keyEquivalent: "")
        shadow.state = .on
        menu.addItem(shadow)
        menu.addItem(NSMenuItem(title: "Only Liked", action: #selector(AppDelegate.onlyLikedDidTap(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Next", action: #selector(AppDelegate.nextDidTap(_:)), keyEquivalent: "N"))
        menu.addItem(NSMenuItem(title: "Like", action: #selector(AppDelegate.likeDidTap(_:)), keyEquivalent: "L"))
        menu.addItem(NSMenuItem(title: "Dislike", action: #selector(AppDelegate.dislikeDidTap(_:)), keyEquivalent: "D"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "Q"))

        statusItem.menu = menu
    }

    @objc func nextDidTap(_ item: NSMenuItem) {
        Logger.debug("next did tap")
        EventBus.next.accept(())
    }

    @objc func likeDidTap(_ item: NSMenuItem) {
        EventBus.like.accept(())
    }

    @objc func dislikeDidTap(_ item: NSMenuItem) {
        EventBus.dislike.accept(())
    }

    @objc func shadowDidTap(_ item: NSMenuItem) {
        let value = EventBus.isShadowed.value
        item.state = value ? .off : .on
        EventBus.isShadowed.accept(!value)
    }

    @objc func onlyLikedDidTap(_ item: NSMenuItem) {
        let value = EventBus.onlyLiked.value
        item.state = value ? .off : .on
        EventBus.onlyLiked.accept(!value)
    }

    @objc func checkForUpdatesDidTap(_ item: NSMenuItem) {
        if let url = URL(string: "https://github.com/jianstm/Mai") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func aboutDidtap(_ item: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}
