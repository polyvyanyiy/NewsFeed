//
//  FavoritesViewModel.swift
//  NewsFeed
//
//  Created by Иван on 09.06.2026.
//

import Foundation

@MainActor
final class FavoritesViewModel {
    
    private(set) var savedItems: [NewsItem] = []
    var onDataUpdated: (([NewsItem]) -> Void)?
    
    func loadData() {
        savedItems = FavoritesStorage.shared.fetchAll()
        onDataUpdated?(savedItems)
    }
    
    func removeItem(id: Int) {
        // Удаляем элемент
        FavoritesStorage.shared.delete(id: id)
        // Сразу перезагружаем актуальный список
        loadData()
    }
}
