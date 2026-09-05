//
//  YippyWindowController.swift
//  Yippy
//
//  Created by Matthew Davidson on 25/9/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift
import RxRelay

class YippyWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = NSWindow.Level(NSWindow.Level.mainMenu.rawValue - 2)
        window?.setAccessibilityIdentifier(Accessibility.identifiers.yippyWindow)
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    static func createYippyWindowController() -> YippyWindowController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(stringLiteral: "YippyWindowController")
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? YippyWindowController else {
            fatalError("Failed to load YippyWindowController of type YippyWindowController from the Main storyboard.")
        }
        
        return windowController
    }
    
    private var oldApp: NSRunningApplication?
    private var dismissWithoutRestoringPreviousApp = false
    private var localMouseDownMonitor: Any?
    private var appResignActiveObserver: NSObjectProtocol?
    
    func subscribeTo(toggle: BehaviorRelay<Bool>) -> Disposable {
        return toggle
            .subscribe(onNext: {
                [] in
                if !$0 {
                    self.stopDismissObservers()
                    self.close()
                    if self.dismissWithoutRestoringPreviousApp {
                        self.dismissWithoutRestoringPreviousApp = false
                    }
                    else {
                        self.oldApp?.activate(options: .activateIgnoringOtherApps)
                    }
                }
                else {
                    self.oldApp = NSWorkspace.shared.frontmostApplication
                    self.showWindow(nil)
                    self.window?.makeKey()
                    NSApp.activate(ignoringOtherApps: true)
                    self.startDismissObservers()
                }
            })
    }
    
    func subscribeFrameTo(position: Observable<PanelPosition>, screen: Observable<NSScreen>) -> Disposable {
        Observable.combineLatest(position, screen).subscribe(onNext: {
            (position, screen) in
            self.window?.setFrame(position.getFrame(forScreen: screen), display: true)
        })
    }

    private func startDismissObservers() {
        stopDismissObservers()

        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) {
            [weak self] event in
            self?.closeIfClickedOutsideYippyWindow(event)
            return event
        }

        appResignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            self?.dismissFromOutsideInteraction()
        }
    }

    private func stopDismissObservers() {
        if let localMouseDownMonitor = localMouseDownMonitor {
            NSEvent.removeMonitor(localMouseDownMonitor)
            self.localMouseDownMonitor = nil
        }

        if let appResignActiveObserver = appResignActiveObserver {
            NotificationCenter.default.removeObserver(appResignActiveObserver)
            self.appResignActiveObserver = nil
        }
    }

    private func closeIfClickedOutsideYippyWindow(_ event: NSEvent) {
        guard let window = window, window.isVisible else {
            return
        }

        if event.window === window {
            return
        }

        dismissFromOutsideInteraction()
    }

    private func dismissFromOutsideInteraction() {
        guard State.main.isHistoryPanelShown.value else {
            return
        }

        dismissWithoutRestoringPreviousApp = true
        State.main.isHistoryPanelShown.accept(false)
    }
}
