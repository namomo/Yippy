//
//  NSTextCheckingResult+Groups.swift
//  Yippy
//
//  Created by Matthew Davidson on 22/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

extension NSTextCheckingResult {
    
    /// https://stackoverflow.com/a/51384977
    func groups(testedString:String) -> [String] {
        var groups = [String]()
        for i in 0 ..< self.numberOfRanges {
            guard let range = Range(self.range(at: i), in: testedString) else {
                continue
            }
            groups.append(String(testedString[range]))
        }
        return groups
    }
}
