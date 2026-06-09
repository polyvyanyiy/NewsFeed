//
//  ImageLoader.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import UIKit

// Сервис изображений с кастомным ImageLoader
@MainActor
final class ImageLoader {
    static let shared = ImageLoader()
    
    // Для сохранения кэша между экранами и сворачиванием
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Лимит кэша
        cache.countLimit = 100
    }
    
    func loadImage(from urlString: String) async -> UIImage? {
        
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return cachedImage
        }
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: urlString as NSString)
            return image
        } catch {
            return nil
        }
    }
}
