//
//  Settings.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/8/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Default
import RxSwift
import RxRelay
import HotKey

struct Settings: Codable, DefaultStorable {
    
    // MARK: - Singleton
    
    private init(
        panelPosition: PanelPosition,
        pasteboardChangeCount: Int,
        toggleHotKey: KeyCombo,
        maxHistory: Int,
        showsRichText: Bool,
        pastesRichText: Bool,
        pinnedHistoryItemIds: [UUID] = []
    ) {
        self.panelPosition = panelPosition
        self.pasteboardChangeCount = pasteboardChangeCount
        self.toggleHotKey = toggleHotKey
        self.maxHistory = maxHistory
        self.showsRichText = showsRichText
        self.pastesRichText = pastesRichText
        self.pinnedHistoryItemIds = pinnedHistoryItemIds
    }
    
    static var main: Settings! {
        get {
            let settings = Settings.read(forKey: "settings")
            if settings != nil {
                return settings
            }
            return Settings.default
        }
        set (main) {
            main.write(withKey: "settings")
        }
    }
    
    // MARK: - Default
    
    static let `default` = Settings(
        panelPosition: .right,
        pasteboardChangeCount: -1,
        toggleHotKey: KeyCombo(key: .v, modifiers: [.command, .shift]),
        maxHistory: Constants.settings.maxHistoryItemsDefault,
        showsRichText: true,
        pastesRichText: true
    )
    
    // MARK: - Settings
    
    var panelPosition: PanelPosition
    
    var pasteboardChangeCount: Int
    
    var toggleHotKey: KeyCombo
    
    var maxHistory: Int
    
    var showsRichText: Bool
    
    var pastesRichText: Bool

    var pinnedHistoryItemIds: [UUID]
    
    
    // MARK: - State Binding Methods
    
    func bindPanelPositionTo(state: BehaviorRelay<PanelPosition>) -> Disposable {
        return state.bind { (x) in
            Settings.main.panelPosition = x
        }
    }
    
    func bindPasteboardChangeCountTo(state: Observable<Int>) -> Disposable {
        return state.bind { (x) in
            Settings.main.pasteboardChangeCount = x
        }
    }
    
    func bindMaxHistoryTo(state: Observable<Int>) -> Disposable {
        return state.bind { (x) in
            Settings.main.maxHistory = x
        }
    }
    
    func bindShowsRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { (x) in
            Settings.main.showsRichText = x
        }
    }
    
    func bindPastesRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { (x) in
            Settings.main.pastesRichText = x
        }
    }
}

extension Settings {
    enum CodingKeys: String, CodingKey {
        case panelPosition
        case pasteboardChangeCount
        case toggleHotKey
        case maxHistory
        case showsRichText
        case pastesRichText
        case pinnedHistoryItemIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            panelPosition: try container.decode(PanelPosition.self, forKey: .panelPosition),
            pasteboardChangeCount: try container.decode(Int.self, forKey: .pasteboardChangeCount),
            toggleHotKey: try container.decode(KeyCombo.self, forKey: .toggleHotKey),
            maxHistory: try container.decode(Int.self, forKey: .maxHistory),
            showsRichText: try container.decode(Bool.self, forKey: .showsRichText),
            pastesRichText: try container.decode(Bool.self, forKey: .pastesRichText),
            pinnedHistoryItemIds: try container.decodeIfPresent([UUID].self, forKey: .pinnedHistoryItemIds) ?? []
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(panelPosition, forKey: .panelPosition)
        try container.encode(pasteboardChangeCount, forKey: .pasteboardChangeCount)
        try container.encode(toggleHotKey, forKey: .toggleHotKey)
        try container.encode(maxHistory, forKey: .maxHistory)
        try container.encode(showsRichText, forKey: .showsRichText)
        try container.encode(pastesRichText, forKey: .pastesRichText)
        try container.encode(pinnedHistoryItemIds, forKey: .pinnedHistoryItemIds)
    }
}

extension Settings {
    
    struct testData {
        static var a: Settings {
            var settings = Settings.default
            settings.panelPosition = .left
            return settings
        }
        
        static func from(_ str: String) -> Settings? {
            switch str {
            case "--Settings.testData=a":
                return a
            default:
                return nil
            }
        }
    }
}

extension Settings: Equatable {
    
}
