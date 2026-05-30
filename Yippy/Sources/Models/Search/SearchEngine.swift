//
//  SearchEngine.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation

struct SearchQuery: Hashable, Equatable {
    
    var query: String
    
    // Enfore the data invariant
    private init(query: String) {
        self.query = query
    }
    
    static func fromRawText(_ str: String) -> SearchQuery {
        return SearchQuery(query: str)
    }
}

public class SearchResult {
    
    let query: SearchQuery
    private(set) var results: [Int] = []
    let items: Int
    private(set) var completed: Int = 0
    
    var isFinished: Bool {
        return completed == items
    }
    
    init(query: SearchQuery, items: Int) {
        self.query = query
        self.items = items
    }
    
    func addResult(_ i: Int) {
        results.append(i)
        completed += 1
    }

    func addResults(_ indexes: [Int]) {
        results.append(contentsOf: indexes)
        completed += indexes.count
    }
    
    func recordFailure() {
        completed += 1
    }
}

public class SearchEngine {

    typealias SearchData = (index: Int, text: String)
    
    private var results = [SearchQuery: SearchResult]()
    
    private var inProgress = [SearchQuery]()
    
    private let stateQueue = DispatchQueue(label: "SearchEngine.state", attributes: .concurrent)
    private let searchQueue = DispatchQueue(label: "SearchEngine.search", qos: .userInitiated)
    
    private let data: [SearchData]
    
    init(data: [SearchData]) {
        self.data = data
    }
    
    public func search(query: String, completion: @escaping (SearchResult) -> Void) {
        let searchQuery = SearchQuery.fromRawText(query)
        
        if let result = findResult(forQuery: searchQuery) {
            return completion(result)
        }
        
        searchQueue.async {
            self.stateQueue.async(flags: .barrier) {
                self.inProgress.append(searchQuery)
            }

            let searchResult = SearchResult(query: searchQuery, items: self.data.count)
            var scoredResults = [(index: Int, score: Int)]()
            for d in self.data {
                if let score = scoreSearch(needle: searchQuery.query, haystack: d.text) {
                    scoredResults.append((index: d.index, score: score))
                }
                else {
                    searchResult.recordFailure()
                }
            }
            searchResult.addResults(scoredResults.sorted(by: { $0.score < $1.score }).map { $0.index })

            self.stateQueue.async(flags: .barrier) {
                self.inProgress.removeAll(where: {$0 == searchQuery})
                self.results[searchQuery] = searchResult
            }

            completion(searchResult)
        }
    }

    private func findResult(forQuery query: SearchQuery) -> SearchResult? {
        var result: SearchResult?
        stateQueue.sync {
            result = results[query]
        }
        return result
    }
}
