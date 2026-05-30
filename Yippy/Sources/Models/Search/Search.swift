//
//  Search.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation

// Adapted from: https://github.com/khoi/fuzzy-swift/blob/master/Sources/Fuzzy/Fuzzy.swift
public func performSearch(needle: String, haystack: String) -> Bool {
    return scoreSearch(needle: needle, haystack: haystack) != nil
}

public func scoreSearch(needle: String, haystack: String) -> Int? {
    guard needle.count <= haystack.count else {
        return nil
    }

    if needle == haystack {
        return 0
    }

    var needleIdx = needle.startIndex
    var haystackIdx = haystack.startIndex
    var score = 0
    var previousMatchIndex: String.Index?

    while needleIdx != needle.endIndex {
        if haystackIdx == haystack.endIndex {
            return nil
        }
        if String(needle[needleIdx]).localizedCaseInsensitiveCompare(String(haystack[haystackIdx])) == .orderedSame {
            let distance = haystack.distance(from: haystack.startIndex, to: haystackIdx)
            score += distance
            if let previousMatchIndex = previousMatchIndex,
                haystack.index(after: previousMatchIndex) != haystackIdx {
                score += 10
            }
            previousMatchIndex = haystackIdx
            needleIdx = needle.index(after: needleIdx)
        }
        haystackIdx = haystack.index(after: haystackIdx)
    }

    return score
}
