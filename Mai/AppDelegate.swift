//
//  AppDelegate.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa
import ScreenSaver

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private var windows: [MaiScreenSaverWindow] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.setupStatusItem()
        self.reloadWindows()
        
        VideoManager.shared.startFetching()
    }

    func reloadWindows() {
        self.windows.forEach { $0.close() }
        self.windows = NSScreen.screens.map { windowWithSaverView(on: $0) }
    }

    func windowWithSaverView(on screen: NSScreen) -> MaiScreenSaverWindow {
        return MaiScreenSaverWindow(screen: screen)
    }
}

// MARK: Menu Item
extension AppDelegate {

    func setupStatusItem() {
        statusItem.button?.image = NSImage(named: "StatusBarButtonImage")

        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "About", action: #selector(AppDelegate.aboutDidtap(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(AppDelegate.checkForUpdatesDidTap(_:)), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        let shadowItem = NSMenuItem(title: "Shadow", action: #selector(AppDelegate.shadowDidTap(_:)), keyEquivalent: "")
        menu.addItem(shadowItem)
        EventBus.isShadowed.bind(to: shadowItem.rx.state).disposed(by: rx.disposeBag)

        menu.addItem(NSMenuItem.separator())

        let stopItem = NSMenuItem(title: "Stop", action: #selector(AppDelegate.stopDidTap(_:)), keyEquivalent: "s")
        menu.addItem(stopItem)
        EventBus.isStopped.bind(to: stopItem.rx.state).disposed(by: rx.disposeBag)
        
        let repeatItem = NSMenuItem(title: "Repeat", action: #selector(AppDelegate.dislikeDidTap(_:)), keyEquivalent: "r")
        menu.addItem(repeatItem)
        EventBus.isStopped.bind(to: repeatItem.rx.state).disposed(by: rx.disposeBag)
        
        let onlyLikedItem = NSMenuItem(title: "Only Liked", action: #selector(AppDelegate.onlyLikedDidTap(_:)), keyEquivalent: "")
        menu.addItem(onlyLikedItem)
        EventBus.onlyLiked.bind(to: onlyLikedItem.rx.state).disposed(by: rx.disposeBag)
        
        menu.addItem(NSMenuItem(title: "Next", action: #selector(AppDelegate.nextDidTap(_:)), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Like", action: #selector(AppDelegate.likeDidTap(_:)), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Dislike", action: #selector(AppDelegate.dislikeDidTap(_:)), keyEquivalent: "d"))
        
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "Q"))

        statusItem.menu = menu
    }

    // MARK: Player Settings
    @objc func shadowDidTap(_ item: NSMenuItem) {
        EventBus.isShadowed.toggle()
    }
    
    // MARK: Control Flows
    @objc func stopDidTap(_ item: NSMenuItem) {
        EventBus.isStopped.toggle()
    }
    
    @objc func repeatDidTap(_ item: NSMenuItem) {
        EventBus.isRepeated.toggle()
    }
    
    @objc func onlyLikedDidTap(_ item: NSMenuItem) {
        EventBus.onlyLiked.toggle()
    }

    @objc func nextDidTap(_ item: NSMenuItem) {
        EventBus.next.accept(())
    }

    @objc func likeDidTap(_ item: NSMenuItem) {
        EventBus.like.accept(())
    }

    @objc func dislikeDidTap(_ item: NSMenuItem) {
        EventBus.dislike.accept(())
    }
    
    // MARK: About & Update
    @objc func aboutDidtap(_ item: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func checkForUpdatesDidTap(_ item: NSMenuItem) {
        guard let url = URL(string: "https://github.com/luoxiu/Mai") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
