//
//  YippyHistory.swift
//  Yippy
//
//  Created by Matthew Davidson on 4/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

class YippyHistory {
    
    let history: History
    var items: [HistoryItem]
    
    let pasteboard: NSPasteboard
    
    init(history: History, items: [HistoryItem]) {
        self.history = history
        self.items = items
        self.pasteboard = NSPasteboard.general
    }
    
    func paste(selected: Int) {
        guard items.indices.contains(selected) else {
            return
        }

        // Internally action the pasteboard change
        // Our pasteboard monitor will detect the change
        // But our `History` will know that it has already been consumed
        let item = items[selected]
        if let historyIndex = history.items.firstIndex(where: { $0 === item }) {
            history.moveItem(at: historyIndex, to: 0)
        }

        let newChangeCount = pasteboard.clearContents()
        history.recordPasteboardChange(withCount: newChangeCount)
        
        // Write object
        pasteboard.writeObjects([item])
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.executePaste(startTime: Date())
            }
        }
    }
    
    private func executePaste(startTime: Date) {
        if NSApp.isActive {
            if Date().timeIntervalSince(startTime) > 2 {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.03) {
                self.executePaste(startTime: startTime)
            }
        }
        else {
            Helper.pressCommandV()
        }
    }
    
    /// Returns the next item to select
    func delete(selected: Int) -> Int? {
        guard items.indices.contains(selected) else {
            return nil
        }

        let item = items[selected]
        guard let historyIndex = history.items.firstIndex(where: { $0 === item }) else {
            return nil
        }

        history.deleteItem(at: historyIndex)
        if historyIndex == 0 {
            // If we want to remove this, then we may have to change the `HistoryItem` writingOptions() to not `.promised`, because if something is pasted from history, then deleted, it can no longer satisfy the promise.
            pasteboard.clearContents()
        }
        
        // Assume no selection
        var select: Int? = nil
        // If the deleted item is not the last in the list then keep the selection index the same.
        if selected < items.count - 1 {
            select = selected
        }
        // Otherwise if there is any items left, select the previous item
        else if selected > 0 {
            select = selected - 1
        }
        // No items, select nothing
        else {
            select = nil
        }
        return select
    }

    func clearClipboard() {
        let newChangeCount = pasteboard.clearContents()
        history.recordPasteboardChange(withCount: newChangeCount)
        history.clear()
    }
    
    func move(from: Int, to: Int) {
        guard items.indices.contains(from), items.indices.contains(to) else {
            return
        }

        let movedItem = items[from]
        let targetItem = items[to]
        guard let historyFrom = history.items.firstIndex(where: { $0 === movedItem }),
            let historyTo = history.items.firstIndex(where: { $0 === targetItem })
        else {
            return
        }

        history.moveItem(at: historyFrom, to: historyTo)
        
        if historyTo == 0 {
            let newChangeCount = pasteboard.clearContents()
            history.recordPasteboardChange(withCount: newChangeCount)
            
            // Write object
            pasteboard.writeObjects([movedItem])
        }
    }
}
