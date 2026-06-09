//
//  R.swift
//  NewsFeed
//
//  Created by Иван on 09.06.2026.
//

import Foundation
import UIKit

enum R {
    enum CoreData {
        static let favoriteNews = "FavoriteNews"
        static let id = "id"
        static let title = "title"
        static let newsDescription = "newsDescription"
        static let url = "url"
        static let fullUrl = "fullUrl"
        static let titleImageUrl = "titleImageUrl"
        static let publishedDate = "publishedDate"
        static let saveAt = "saveAt"
    }
    
    enum Image {
        static let heartFill = UIImage(systemName: "heart.fill")
        static let heart = UIImage(systemName: "heart")
        static let circle3x3 = UIImage(systemName: "circle.grid.3x3")
        static let rectangle1x2 = UIImage(systemName: "rectangle.grid.1x2")
        static let square2x2 = UIImage(systemName: "square.grid.2x2")
        static let square3x3 = UIImage(systemName: "square.grid.3x3")
    }
    
    enum ImageString {
        static let heartFill = "heart.fill"
        static let heart = "heart"
        static let newspaper = "newspaper"
    }
    
    enum Column: String {
        case one = "Сетка 1х1"
        case two = "Сетка 2х2"
        case three = "Сетка 3х3"
    }
}
