//
//  Model.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import Foundation

struct NewsResponse: Codable {
    let news: [NewsItem]
    let totalCount: Int
}

nonisolated struct NewsItem: Codable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String?
    let url: String
    let fullUrl: String // full для WebView
    let titleImageUrl: String?
    let publishedDate: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
        lhs.id == rhs.id
    }
}
