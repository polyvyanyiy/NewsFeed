//
//  FavoritesStorage.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import CoreData

@MainActor
final class FavoritesStorage {
    static let shared = FavoritesStorage()
    
    private let container: NSPersistentContainer
    
    private init() {
        // Описываем сущность для CoreData динамически в коде
        let entity = NSEntityDescription()
        entity.name = R.CoreData.favoriteNews
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        // Описываем атрибуты
        let idAttr = NSAttributeDescription()
        idAttr.name = R.CoreData.id
        idAttr.attributeType = .integer64AttributeType
        
        let titleAttr = NSAttributeDescription()
        titleAttr.name = R.CoreData.title
        titleAttr.attributeType = .stringAttributeType
        
        let descAttr = NSAttributeDescription()
        descAttr.name = R.CoreData.newsDescription
        descAttr.attributeType = .stringAttributeType
        
        let urlAttr = NSAttributeDescription()
        urlAttr.name = R.CoreData.url
        urlAttr.attributeType = .stringAttributeType
        
        let fullUrlAttr = NSAttributeDescription()
        fullUrlAttr.name = R.CoreData.fullUrl
        fullUrlAttr.attributeType = .stringAttributeType
        
        let imageAttr = NSAttributeDescription()
        imageAttr.name = R.CoreData.titleImageUrl
        imageAttr.attributeType = .stringAttributeType
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = R.CoreData.publishedDate
        dateAttr.attributeType = .stringAttributeType
        
        let saveAt = NSAttributeDescription()
        saveAt.name = R.CoreData.saveAt
        saveAt.attributeType = .dateAttributeType
        
        entity.properties = [idAttr, titleAttr, descAttr, urlAttr, fullUrlAttr, imageAttr, dateAttr, saveAt]
        
        let model = NSManagedObjectModel()
        model.entities = [entity]
        
        container = NSPersistentContainer(name: "FavoritesModel", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData load error: \(error)")
            }
        }
    }
    
    // сохранение
    func save(_ item: NewsItem) {
        if isFavorite(id: item.id) { return }
        let context = container.viewContext
        let object = NSManagedObject(entity: container.managedObjectModel.entities[0], insertInto: context)
        object.setValue(Int64(item.id), forKey: R.CoreData.id)
        object.setValue(item.title, forKey: R.CoreData.title)
        object.setValue(item.description, forKey: R.CoreData.newsDescription)
        object.setValue(item.url, forKey: R.CoreData.url)
        object.setValue(item.fullUrl, forKey: R.CoreData.fullUrl)
        object.setValue(item.titleImageUrl, forKey: R.CoreData.titleImageUrl)
        object.setValue(item.publishedDate, forKey: R.CoreData.publishedDate)
        object.setValue(Date(), forKey: R.CoreData.saveAt)
        try? context.save()
    }
    
    // удаление
    func delete(id: Int) {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: R.CoreData.favoriteNews)
        request.predicate = NSPredicate(format: "id == %lld", Int64(id))
        if let objects = try? context.fetch(request) {
            for object in objects {
                context.delete(object)
            }
            try? context.save()
        }
    }
    
    // Получить чек на избранное
    func isFavorite(id: Int) -> Bool {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: R.CoreData.favoriteNews)
        request.predicate = NSPredicate(format: "id == %lld", Int64(id))
        let count = (try? context.count(for: request)) ?? 0
        return count > 0
    }
    
    // Получить данные
    func fetchAll() -> [NewsItem] {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: R.CoreData.favoriteNews)
        
        let sortDescriptor = NSSortDescriptor(key: R.CoreData.saveAt, ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        guard let objects = try? context.fetch(request) else { return [] }
        
        return objects.map { obj in
            NewsItem(
                id: Int(obj.value(forKey: R.CoreData.id) as? Int64 ?? 0),
                title: obj.value(forKey: R.CoreData.title) as? String ?? "",
                description: obj.value(forKey: R.CoreData.newsDescription) as? String,
                url: obj.value(forKey: R.CoreData.url) as? String ?? "",
                fullUrl: obj.value(forKey: R.CoreData.fullUrl) as? String ?? "",
                titleImageUrl: obj.value(forKey: R.CoreData.titleImageUrl) as? String,
                publishedDate: obj.value(forKey: R.CoreData.publishedDate) as? String ?? ""
            )
        }
    }
}
