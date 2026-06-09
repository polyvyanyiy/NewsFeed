//
//  NewsViewController.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import UIKit
import Combine

nonisolated enum LayoutMode: Int, Sendable {
    case oneColumn = 1   // 1х1
    case twoColumns = 2  // 2х2
    case threeColumns = 3 // 3х3
}

nonisolated enum NewsSection: Hashable, Sendable {
    case main
}

@MainActor
final class NewsViewController: UIViewController {
    
    private let viewModel = NewsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<NewsSection, NewsItem>!
    
    // настройка сетки
    private var currentLayoutMode: LayoutMode = .oneColumn
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Автодок Новости"
        view.backgroundColor = .systemBackground
        
        setupNavigationMenu()
        setupCollectionView()
        configureDataSource()
        bindViewModel()
        
        viewModel.loadNextPage()
    }
    
    // MARK: - Настройка сетки
    private func setupNavigationMenu() {
        let oneColumnAction = UIAction(title: R.Column.one.rawValue, image: R.Image.rectangle1x2) { [weak self] _ in
            self?.updateLayoutMode(.oneColumn)
        }
        let twoColumnsAction = UIAction(title: R.Column.two.rawValue, image: R.Image.square2x2) { [weak self] _ in
            self?.updateLayoutMode(.twoColumns)
        }
        let threeColumnsAction = UIAction(title: R.Column.three.rawValue, image: R.Image.square3x3) { [weak self] _ in
            self?.updateLayoutMode(.threeColumns)
        }
        
        let menu = UIMenu(title: "Выбирите сетку", children: [oneColumnAction, twoColumnsAction, threeColumnsAction])
        
        let menuButton = UIBarButtonItem(title: nil, image: R.Image.circle3x3, target: self, action: nil)
        menuButton.menu = menu
        navigationItem.leftBarButtonItem = menuButton
        
        let favoritesButton = UIBarButtonItem(image: R.Image.heartFill, style: .plain, target: self, action: #selector(openFavorites))
        favoritesButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = favoritesButton
    }
    
    @objc private func openFavorites() {
        let favoritesVC = FavoritesViewController()
        navigationController?.pushViewController(favoritesVC, animated: true)
    }
    
    // Переключаем режима сетки
    private func updateLayoutMode(_ mode: LayoutMode) {
        self.currentLayoutMode = mode
        
        // Пересчитываем координаты
        collectionView.collectionViewLayout.invalidateLayout()
        
        var currentSnapshot = dataSource.snapshot()
        let allIdentifiers = currentSnapshot.itemIdentifiers
        
        // Обновляем/перерисовываем ячейки
        currentSnapshot.reconfigureItems(allIdentifiers)
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }

    
    // MARK: - Compositional Layout (iPad Оптимизация)
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, environment in
            guard let self = self else { return nil }
            
            // Количество колонок
            let columns = self.currentLayoutMode.rawValue
            // Рассчитываем размер элемента
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
            
            // Создаем группу для элементов
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
            return section
        }
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.register(NewsCell.self, forCellWithReuseIdentifier: NewsCell.reuseIdentifier)
        
        view.addSubview(collectionView)
    }

    // MARK: - Diffable Data Source
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<NewsSection, NewsItem>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return UICollectionViewCell() }
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NewsCell.reuseIdentifier,
                for: indexPath
            ) as? NewsCell ?? NewsCell()
            
            cell.configure(with: item)
            cell.applyLayoutMode(self.currentLayoutMode)
            
            // Событие добавления/удаления избранного
            cell.onFavoriteToggled = { [weak self, weak cell] in
                guard let self = self else { return }
                
                if FavoritesStorage.shared.isFavorite(id: item.id) {
                    FavoritesStorage.shared.delete(id: item.id)
                } else {
                    FavoritesStorage.shared.save(item)
                }
                
                cell?.applyLayoutMode(self.currentLayoutMode)
            }
            
            return cell
        }
    }

    // MARK: - ViewModel Binding (Combine)
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .initial:
                    break
                case .loading:
                    break
                case .loaded(let news):
                    self?.applySnapshot(with: news)
                case .error(let error):
                    self?.showError(error as! Error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func applySnapshot(with news: [NewsItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<NewsSection, NewsItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(news, toSection: .main)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Перерисовываем видимые ячейки
        var currentSnapshot = dataSource.snapshot()
        let allIdentifiers = currentSnapshot.itemIdentifiers
        
        // Проверяем наличие элементов
        guard !allIdentifiers.isEmpty else { return }
        currentSnapshot.reloadItems(allIdentifiers)
        
        dataSource.apply(currentSnapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate (Пагинация и нажатия)
extension NewsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        // Открытие webView по fullUrl
        let webVC = WebViewController(urlString: item.fullUrl)
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        guard contentHeight > 0 else { return }
        
        // Триггер пагинации
        if offsetY > (contentHeight - frameHeight) * 0.8 {
            viewModel.loadNextPage()
        }
    }
}
