//
//  NewsCell.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import UIKit

final class NewsCell: UICollectionViewCell {
    
    static let reuseIdentifier = "NewsCell"
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 12
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.numberOfLines = 0
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let badgeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 2.0
        label.layer.shadowOpacity = 0.8
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.masksToBounds = false
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let favoriteButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: R.ImageString.heart, withConfiguration: config), for: .normal)
        button.tintColor = .systemRed
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var favoriteButtonWidthConstraint: NSLayoutConstraint?
    private var favoriteButtonHeightConstraint: NSLayoutConstraint?
    private var currentNewsItemId: Int?
    
    private var imageFetchTask: Task<Void, Never>?
    var onFavoriteToggled: (() -> Void)?
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        // Основная ячейка
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        // Дата
        imageView.addSubview(badgeContainerView)
        badgeContainerView.addSubview(dateLabel)
        // Избранное
        imageView.addSubview(favoriteButton)
        imageView.isUserInteractionEnabled = true
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        
        let heightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.6)
        heightConstraint.priority = UILayoutPriority(999)
        let bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        bottomConstraint.priority = UILayoutPriority(999)
        
        favoriteButtonWidthConstraint = favoriteButton.widthAnchor.constraint(equalToConstant: 32)
        favoriteButtonHeightConstraint = favoriteButton.heightAnchor.constraint(equalToConstant: 32)
        
        NSLayoutConstraint.activate([
            // картинка
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            heightConstraint,
            
            // избранное
            favoriteButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            favoriteButton.rightAnchor.constraint(equalTo: imageView.rightAnchor, constant: -8),
            favoriteButtonWidthConstraint!,
            favoriteButtonHeightConstraint!,
            
            // рамка даты
            badgeContainerView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -3),
            badgeContainerView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -3),
            // дата
            dateLabel.topAnchor.constraint(equalTo: badgeContainerView.topAnchor, constant: 4),
            dateLabel.bottomAnchor.constraint(equalTo: badgeContainerView.bottomAnchor, constant: -4),
            dateLabel.leadingAnchor.constraint(equalTo: badgeContainerView.leadingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: badgeContainerView.trailingAnchor, constant: -8),
            
            // текст
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            bottomConstraint
        ])

    }
    
    func configure(with item: NewsItem) {
        self.currentNewsItemId = item.id
        titleLabel.text = item.title
        
        if let fullDate = item.publishedDate.components(separatedBy: "T").first {
            dateLabel.text = fullDate
        } else {
            dateLabel.text = item.publishedDate
        }
        
        imageView.image = nil // сброс картинки
        
        // Растягиваем картинку
        let largeSymbolConfig = UIImage.SymbolConfiguration(pointSize: 64, weight: .regular)
        // Создаем картинку(загрушку), на случай если к нам ничего не пришло
        let placeholderImage = UIImage(
            systemName: R.ImageString.newspaper,
            withConfiguration: largeSymbolConfig
        )?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        
        guard let imageUrlString = item.titleImageUrl, !imageUrlString.isEmpty else {
            imageView.contentMode = .center // Центрируем иконку
            imageView.image = placeholderImage
            return
        }
        
        // Асинхронная загрузка
        imageFetchTask = Task { [weak self] in
            let image = await ImageLoader.shared.loadImage(from: imageUrlString)
            
            // делаем проверку на возможную отмену
            if !Task.isCancelled {
                if let downloadedImage = image {
                    // Если загрузка прошла успешно — растягиваем и показываем новостное фото
                    self?.imageView.contentMode = .scaleAspectFill
                    self?.imageView.image = downloadedImage
                } else {
                    // Если картинка не скачалась — ставим заглушку
                    self?.imageView.contentMode = .center
                    self?.imageView.image = placeholderImage
                }
            }
        }
    }
    
    @objc private func favoriteButtonTapped() {
        onFavoriteToggled?()
    }
    
    func applyLayoutMode(_ mode: LayoutMode) {
        // Базовые константы для iPhone
        let baseFontSize: CGFloat = 22.0
        let baseButtonSize: CGFloat = 32.0
        let baseDateFontSize: CGFloat = 12.0
        let baseDateBorderWidth: CGFloat = 1.0
        
        // Проверка типа устройства (iPad / iPhone)
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        var heartScale: CGFloat = 1.0
        var dateScale: CGFloat = 1.0
        
        switch mode {
        case .oneColumn: // Сетка 1х1
            badgeContainerView.isHidden = false
            heartScale = isPad ? 2.0 : 1.0
            dateScale = isPad ? 2.0 : 1.0
            
        case .twoColumns: // Сетка 2х2
            badgeContainerView.isHidden = false
            heartScale = isPad ? 1.5 : 0.8
            dateScale = isPad ? 1.5 : 0.8
            
        case .threeColumns: // Сетка 3х3
            if isPad {
                badgeContainerView.isHidden = false
                heartScale = 1.0
                dateScale = 1.0
            } else {
                badgeContainerView.isHidden = true // Скрываем дату на iPhone
                heartScale = 0.6
            }
        }
        
        let newHeartFontSize = baseFontSize * heartScale
        let config = UIImage.SymbolConfiguration(pointSize: newHeartFontSize, weight: .semibold)
        
        let isFav = FavoritesStorage.shared.isFavorite(id: currentNewsItemId ?? 0)
        let heartImage = UIImage(systemName: isFav ? R.ImageString.heartFill : R.ImageString.heart,
                                 withConfiguration: config)
        favoriteButton.setImage(heartImage, for: .normal)
        
        // Размер избранного
        let newButtonSize = baseButtonSize * heartScale
        favoriteButtonWidthConstraint?.constant = newButtonSize
        favoriteButtonHeightConstraint?.constant = newButtonSize
        
        // размер даты
        if !badgeContainerView.isHidden {
            dateLabel.font = .systemFont(ofSize: baseDateFontSize * dateScale, weight: .bold)
            badgeContainerView.layer.borderWidth = baseDateBorderWidth * dateScale
        }
        
        // Обновляем
        contentView.layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Отменяем старую задачу, чтобы картинки не было в другой ячейки
        imageFetchTask?.cancel()
        imageFetchTask = nil
        imageView.image = nil
        dateLabel.text = nil
    }
}
