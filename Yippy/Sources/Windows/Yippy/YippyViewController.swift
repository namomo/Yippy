//
//  YippyViewController.swift
//  Yippy
//
//  Created by Matthew Davidson on 26/7/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Cocoa
import HotKey
import RxSwift
import RxRelay
import RxCocoa

struct Results {
    let items: [HistoryItem]
    let isSearchResult: Bool
}

enum YippyItemGroup: Int {
    case clipboard
    case pinned

    static let titles = ["Clipboard", "Pinned"]
}

class YippyViewController: NSViewController {
    
    @IBOutlet var yippyHistoryView: YippyTableView!
    
    @IBOutlet var itemGroupScrollView: HorizontalButtonsView!
    @IBOutlet var itemCountLabel: NSTextField!
    
    @IBOutlet var searchBar: NSTextField!

    private var clearClipboardButton: NSButton!
    
    var yippyHistory = YippyHistory(history: State.main.history, items: [])
    
    var searchEngine = SearchEngine(data: [])
    var searchRevision = 0
    var searchSourceItems = [HistoryItem]()
    
    let disposeBag = DisposeBag()
    
    var isPreviewShowing = false
    
    var itemGroups = BehaviorRelay<[String]>(value: YippyItemGroup.titles)
    var selectedItemGroup = BehaviorRelay<Int>(value: YippyItemGroup.clipboard.rawValue)
    
    var isRichText = Settings.main.showsRichText
    
    let results = BehaviorRelay(value: Results(items: [], isSearchResult: false))
    let selected = BehaviorRelay<Int?>(value: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        yippyHistoryView.yippyDelegate = self
        
        State.main.history.subscribe(onNext: onHistoryChange)
        
        State.main.showsRichText.distinctUntilChanged().subscribe(onNext: onShowsRichText).disposed(by: disposeBag)
        
        itemGroupScrollView.bind(toData: itemGroups.asObservable()).disposed(by: disposeBag)
        itemGroupScrollView.bind(toSelected: selectedItemGroup.asObservable()).disposed(by: disposeBag)
        itemGroupScrollView.yippyDelegate = self
        itemGroupScrollView.constraint(withIdentifier: "height")?.constant = 28
        
        Observable.combineLatest(
            results,
            selected.distinctUntilChanged().withPrevious(startWith: nil)
        )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: onAllChange)
            .disposed(by: disposeBag)
        
        searchBar.delegate = self
        setupClearClipboardButton()
        
        // TODO: Fix hack to make onAllChange run initially
        selected.accept(1)
        resetSelected()
        
        YippyHotKeys.downArrow.onDown(goToNextItem)
        YippyHotKeys.downArrow.onLong(goToNextItem)
        YippyHotKeys.pageDown.onDown(goToNextItem)
        YippyHotKeys.pageDown.onLong(goToNextItem)
        YippyHotKeys.upArrow.onDown(goToPreviousItem)
        YippyHotKeys.upArrow.onLong(goToPreviousItem)
        YippyHotKeys.pageUp.onDown(goToPreviousItem)
        YippyHotKeys.pageUp.onLong(goToPreviousItem)
        YippyHotKeys.escape.onDown(close)
        YippyHotKeys.return.onDown(pasteSelected)
        YippyHotKeys.ctrlAltCmdLeftArrow.onDown { State.main.panelPosition.accept(.left) }
        YippyHotKeys.ctrlAltCmdRightArrow.onDown { State.main.panelPosition.accept(.right) }
        YippyHotKeys.ctrlAltCmdDownArrow.onDown { State.main.panelPosition.accept(.bottom) }
        YippyHotKeys.ctrlAltCmdUpArrow.onDown { State.main.panelPosition.accept(.top) }
        YippyHotKeys.ctrlDelete.onDown(deleteSelected)
        YippyHotKeys.ctrlSpace.onDown(togglePreview)
        YippyHotKeys.cmdBackslash.onDown(focusSearchBar)
        
        // Paste hot keys
        YippyHotKeys.cmd0.onDown { self.shortcutPressed(key: 0) }
        YippyHotKeys.cmd1.onDown { self.shortcutPressed(key: 1) }
        YippyHotKeys.cmd2.onDown { self.shortcutPressed(key: 2) }
        YippyHotKeys.cmd3.onDown { self.shortcutPressed(key: 3) }
        YippyHotKeys.cmd4.onDown { self.shortcutPressed(key: 4) }
        YippyHotKeys.cmd5.onDown { self.shortcutPressed(key: 5) }
        YippyHotKeys.cmd6.onDown { self.shortcutPressed(key: 6) }
        YippyHotKeys.cmd7.onDown { self.shortcutPressed(key: 7) }
        YippyHotKeys.cmd8.onDown { self.shortcutPressed(key: 8) }
        YippyHotKeys.cmd9.onDown { self.shortcutPressed(key: 9) }
        
        bindHotKeyToYippyWindow(YippyHotKeys.downArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.upArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.return, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.escape, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageDown, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageUp, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdLeftArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdRightArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdDownArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdUpArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd0, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd1, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd2, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd3, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd4, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd5, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd6, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd7, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd8, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd9, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlDelete, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlSpace, disposeBag: disposeBag)
        
        searchBar.resignFirstResponder()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        isPreviewShowing = false
        resetSelected()
    }
    
    func resetSelected() {
        if yippyHistory.items.count > 0 {
            selected.accept(0)
        }
        else {
            selected.accept(nil)
        }
    }
    
    func onHistoryChange(_ history: [HistoryItem], change: History.Change) {
        updateCellHeightCache(for: change)
        refreshDisplayedItems()

        if searchBar.stringValue.isEmpty {
            switch change {
            case .insert(let i) where selectedGroup == .clipboard && i == 0:
                incrementSelected()
            default:
                break
            }
        }
    }
    
    func updateSearchEngine(items: [HistoryItem]) {
        searchRevision += 1
        let searchData = items.enumerated().compactMap { index, item -> SearchEngine.SearchData? in
            guard let text = item.getPlainString() else {
                return nil
            }
            return (index: index, text: text)
        }
        searchSourceItems = items
        self.searchEngine = SearchEngine(data: searchData)
    }

    var selectedGroup: YippyItemGroup {
        return YippyItemGroup(rawValue: selectedItemGroup.value) ?? .clipboard
    }

    private func setupClearClipboardButton() {
        clearClipboardButton = NSButton(title: "Clear", target: self, action: #selector(clearClipboardClicked))
        clearClipboardButton.bezelStyle = .rounded
        clearClipboardButton.font = NSFont.systemFont(ofSize: 12)
        clearClipboardButton.setAccessibilityIdentifier(Accessibility.identifiers.clearClipboardButton)
        clearClipboardButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearClipboardButton)

        view.constraints
            .filter {
                ($0.firstItem as AnyObject?) === searchBar && $0.firstAttribute == .trailing
                || ($0.secondItem as AnyObject?) === searchBar && $0.secondAttribute == .trailing
            }
            .forEach { $0.isActive = false }

        NSLayoutConstraint.activate([
            clearClipboardButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            clearClipboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            clearClipboardButton.widthAnchor.constraint(equalToConstant: 58),
            clearClipboardButton.heightAnchor.constraint(equalToConstant: 28),
            searchBar.trailingAnchor.constraint(equalTo: clearClipboardButton.leadingAnchor, constant: -8),
        ])

        updateClearClipboardButtonVisibility()
    }

    func displayedItems() -> [HistoryItem] {
        switch selectedGroup {
        case .clipboard:
            return State.main.history.items
        case .pinned:
            return pinnedItems()
        }
    }

    func pinnedItems() -> [HistoryItem] {
        let itemsById = Dictionary(uniqueKeysWithValues: State.main.history.items.map { ($0.fsId, $0) })
        return Settings.main.pinnedHistoryItemIds.compactMap { itemsById[$0] }
    }

    func refreshDisplayedItems() {
        let items = displayedItems()
        updateSearchEngine(items: items)
        updateClearClipboardButtonVisibility()

        if searchBar.stringValue.isEmpty {
            results.accept(Results(items: items, isSearchResult: false))
        }
        else {
            runSearch()
        }

        if let selected = selected.value, !items.indices.contains(selected) {
            resetSelected()
        }
    }
    
    func onAllChange(_ results: Results, _ selected: (Int?, Int?)) {
        if results.items != self.yippyHistory.items {
                if results.isSearchResult {
                    self.itemCountLabel.stringValue = "\(results.items.count) matches"
                }
                else {
                    self.itemCountLabel.stringValue = "\(results.items.count) items"
                }
                
                self.yippyHistory = YippyHistory(history: State.main.history, items: results.items)
                self.yippyHistoryView.reloadData(self.yippyHistory.items, isRichText: self.isRichText)
            }
        
        if let previous = selected.0, self.yippyHistory.items.indices.contains(previous) {
            self.yippyHistoryView.deselectItem(previous)
            self.yippyHistoryView.reloadItem(previous)
        }
        if let selected = selected.1, self.yippyHistory.items.indices.contains(selected) {
            let currentSelection = self.yippyHistoryView.selected
            if currentSelection == nil || currentSelection != selected {
                self.yippyHistoryView.selectItem(selected)
            }
            self.yippyHistoryView.reloadItem(selected)
            
            if self.isPreviewShowing {
                State.main.previewHistoryItem.accept(self.yippyHistory.items[selected])
            }
        }
    }
    
    func onShowsRichText(_ showsRichText: Bool) {
        isRichText = showsRichText
        yippyHistoryView.clearCellHeightCache()
        yippyHistoryView.reloadData(yippyHistory.items, isRichText: isRichText)
    }

    func updateCellHeightCache(for change: History.Change) {
        switch change {
        case .delete(let deletedItem):
            yippyHistoryView.removeCellHeight(for: deletedItem)
        case .clear:
            yippyHistoryView.clearCellHeightCache()
        case .itemLimitDecreased(let deletedItems):
            deletedItems.forEach { yippyHistoryView.removeCellHeight(for: $0) }
        default:
            break
        }
    }
    
    func bindHotKeyToYippyWindow(_ hotKey: YippyHotKey, disposeBag: DisposeBag) {
        State.main.isHistoryPanelShown
            .distinctUntilChanged()
            .subscribe(onNext: { [] in
                hotKey.isPaused = !$0
            })
            .disposed(by: disposeBag)
    }
    
    func goToNextItem() {
        incrementSelected()
    }
    
    func goToPreviousItem() {
        decrementSelected()
    }
    
    func pasteSelected() {
        if let selected = self.yippyHistoryView.selected {
            paste(selected: selected)
        }
    }

    @objc func clearClipboardClicked() {
        guard selectedGroup == .clipboard else {
            return
        }

        searchBar.stringValue = ""
        State.main.previewHistoryItem.accept(nil)
        isPreviewShowing = false
        yippyHistory.clearClipboard()
        refreshDisplayedItems()
        resetSelected()
    }
    
    func deleteSelected() {
        if let selected = self.yippyHistoryView.selected {
            if selectedGroup == .pinned {
                self.selected.accept(unpinSelected())
                return
            }
            self.selected.accept(yippyHistory.delete(selected: selected))
        }
    }
    
    func close() {
        isPreviewShowing = false
        State.main.isHistoryPanelShown.accept(false)
        State.main.previewHistoryItem.accept(nil)
        resetSelected()
    }
    
    func shortcutPressed(key: Int) {
        guard yippyHistory.items.indices.contains(key) else {
            return
        }
        paste(selected: key)
    }
    
    func togglePreview() {
        if let selected = yippyHistoryView.selected, yippyHistory.items.indices.contains(selected) {
            isPreviewShowing = !isPreviewShowing
            if isPreviewShowing {
                State.main.previewHistoryItem.accept(yippyHistory.items[selected])
            }
            else {
                State.main.previewHistoryItem.accept(nil)
            }
        }
    }
    
    func focusSearchBar() {
        NSApp.activate(ignoringOtherApps: true)
        self.searchBar.becomeFirstResponder()
    }

    private func updateClearClipboardButtonVisibility() {
        clearClipboardButton?.isHidden = selectedGroup != .clipboard
    }
    
    func runSearch() {
        let query = searchBar.stringValue
        let revision = searchRevision
        searchEngine.search(query: query, completion: { result in
            DispatchQueue.main.async {
                guard self.searchRevision == revision && self.searchBar.stringValue == result.query.query else {
                    return
                }

                if result.query.query.isEmpty {
                    self.results.accept(Results(items: self.displayedItems(), isSearchResult: false))
                    return
                }

                var filteredData = [HistoryItem]()
                for i in result.results where self.searchSourceItems.indices.contains(i) {
                    filteredData.append(self.searchSourceItems[i])
                }

                self.results.accept(Results(items: filteredData, isSearchResult: true))
            }
        })
    }
    
    private func incrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s < yippyHistory.items.count - 1 {
            selected.accept(s + 1)
        }
    }
    
    private func decrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s > 0 {
            selected.accept(s - 1)
        }
    }
    
    private func paste(selected: Int) {
        guard yippyHistory.items.indices.contains(selected) else {
            return
        }
        self.close()
        yippyHistory.paste(selected: selected)
    }

    func isPinned(_ item: HistoryItem) -> Bool {
        return Settings.main.pinnedHistoryItemIds.contains(item.fsId)
    }

    func pin(_ item: HistoryItem) {
        guard !isPinned(item) else {
            return
        }

        var settings: Settings = Settings.main
        settings.pinnedHistoryItemIds.insert(item.fsId, at: 0)
        Settings.main = settings
        refreshDisplayedItems()
    }

    func unpin(_ item: HistoryItem) {
        var settings: Settings = Settings.main
        settings.pinnedHistoryItemIds.removeAll(where: { $0 == item.fsId })
        Settings.main = settings
        refreshDisplayedItems()
    }

    func unpinSelected() -> Int? {
        guard let selected = yippyHistoryView.selected, yippyHistory.items.indices.contains(selected) else {
            return nil
        }

        unpin(yippyHistory.items[selected])
        if selected < yippyHistory.items.count - 1 {
            return selected
        }
        if selected > 0 {
            return selected - 1
        }
        return nil
    }

    func reorderPinned(from: Int, to: Int) {
        guard selectedGroup == .pinned,
            yippyHistory.items.indices.contains(from),
            yippyHistory.items.indices.contains(to)
        else {
            return
        }

        let movedId = yippyHistory.items[from].fsId
        let targetId = yippyHistory.items[to].fsId
        var pinnedIds = Settings.main.pinnedHistoryItemIds
        guard let fromIndex = pinnedIds.firstIndex(of: movedId),
            let toIndex = pinnedIds.firstIndex(of: targetId)
        else {
            return
        }

        let removed = pinnedIds.remove(at: fromIndex)
        pinnedIds.insert(removed, at: toIndex)
        var settings: Settings = Settings.main
        settings.pinnedHistoryItemIds = pinnedIds
        Settings.main = settings
        refreshDisplayedItems()
    }

    @objc func pinMenuItemClicked(_ sender: NSMenuItem) {
        guard yippyHistory.items.indices.contains(sender.tag) else {
            return
        }
        pin(yippyHistory.items[sender.tag])
    }

    @objc func unpinMenuItemClicked(_ sender: NSMenuItem) {
        guard yippyHistory.items.indices.contains(sender.tag) else {
            return
        }
        unpin(yippyHistory.items[sender.tag])
    }

    @objc func deleteMenuItemClicked(_ sender: NSMenuItem) {
        guard yippyHistory.items.indices.contains(sender.tag) else {
            return
        }
        selected.accept(yippyHistory.delete(selected: sender.tag))
    }
}

extension YippyViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        runSearch()
    }
}

extension YippyViewController: YippyTableViewDelegate {
    func yippyTableView(_ yippyTableView: YippyTableView, selectedDidChange selected: Int?) {
        self.selected.accept(selected)
    }
    
    func yippyTableView(_ yippyTableView: YippyTableView, didMoveItem from: Int, to: Int) {
        if selectedGroup == .pinned {
            reorderPinned(from: from, to: to)
            selected.accept(to)
            return
        }

        yippyHistory.move(from: from, to: to)
        selected.accept(to)
    }

    func yippyTableView(_ yippyTableView: YippyTableView, menuForItemAt row: Int) -> NSMenu? {
        guard yippyHistory.items.indices.contains(row) else {
            return nil
        }

        let item = yippyHistory.items[row]
        let menu = NSMenu()
        if isPinned(item) {
            menu.addItem(NSMenuItem(title: "Remove from Pinned", action: #selector(unpinMenuItemClicked(_:)), keyEquivalent: ""))
        }
        else {
            menu.addItem(NSMenuItem(title: "Pin", action: #selector(pinMenuItemClicked(_:)), keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Delete Item", action: #selector(deleteMenuItemClicked(_:)), keyEquivalent: ""))
        menu.items.forEach {
            $0.target = self
            $0.tag = row
        }
        return menu
    }
}

extension YippyViewController: HorizontalButtonsViewDelegate {
    func horizontalButtonsView(_ horizontalButtonsView: HorizontalButtonsView, didClickButtonAt i: Int) {
        guard YippyItemGroup(rawValue: i) != nil else {
            return
        }

        selectedItemGroup.accept(i)
        selected.accept(nil)
        refreshDisplayedItems()
        resetSelected()
    }
}
