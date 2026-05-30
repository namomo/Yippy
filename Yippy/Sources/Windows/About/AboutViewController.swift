//
//  AboutViewController.swift
//  Yippy
//
//  Created by Matthew Davidson on 13/9/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

class AboutViewController: NSViewController {
    
    @IBOutlet var versionLabel: NSTextField!
    
    @IBOutlet var infoTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        versionLabel.stringValue = "Version \(version) (\(build))"
        
        infoTextView.isAutomaticLinkDetectionEnabled = true
        // https://stackoverflow.com/a/25762502
        infoTextView.isEditable = true
        infoTextView.checkTextInDocument(nil)
        infoTextView.isEditable = false
    }
}
