//
//  NetworkService.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import Foundation

protocol NetworkServiceProtocol {
    func fetchNews(page: Int, pageSize: Int) async throws -> NewsResponse
}

final class NetworkService: NetworkServiceProtocol {
    func fetchNews(page: Int, pageSize: Int) async throws -> NewsResponse {
        let url = try await getUrl(page: page, pageSize: pageSize)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(NewsResponse.self, from: data)
    }
    
    // метод для получения URL
    private func getUrl(page: Int, pageSize: Int) async throws -> URL {
        let urlString = "https://webapi.autodoc.ru/api/news/\(page)/\(pageSize)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        return url
    }
}
