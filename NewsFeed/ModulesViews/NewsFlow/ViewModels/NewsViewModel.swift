//
//  NewsViewModel.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import Foundation
import Combine

enum ViewModelState: Sendable {
    case initial
    case loading
    case loaded([NewsItem])
    case error(String)
}

@MainActor
final class NewsViewModel {
    @Published private(set) var state: ViewModelState = .initial
    
    private let networkService: NetworkServiceProtocol
    private var allNews: [NewsItem] = []
    
    // Пагинации
    private var currentPage = 1
    private let pageSize = 15
    private var totalCount = 0
    private var isCurrentlyLoading = false
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func loadNextPage() {
        guard !isCurrentlyLoading else { return }
        if !allNews.isEmpty && allNews.count >= totalCount { return }
        
        isCurrentlyLoading = true
        if allNews.isEmpty {
            state = .loading
        }
        
        Task {
            do {
                let response = try await self.networkService.fetchNews(page: self.currentPage, pageSize: self.pageSize)
                
                self.totalCount = response.totalCount
                self.allNews.append(contentsOf: response.news)
                self.currentPage += 1
                
                self.state = .loaded(self.allNews)
            } catch {
                self.state = .error(error.localizedDescription)
            }
            self.isCurrentlyLoading = false
        }
    }
}
