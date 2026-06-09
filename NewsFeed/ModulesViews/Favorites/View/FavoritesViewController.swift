//
//  FavoritesViewController.swift
//  NewsFeed
//
//  Created by Иван on 08.06.2026.
//

import UIKit

@MainActor
final class FavoritesViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<NewsSection, NewsItem>!
    
    private let viewModel = FavoritesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Избранное"
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
        configureDataSource()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadData()
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] items in
            self?.applySnapshot(with: items)
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            let width = environment.container.contentSize.width
            let columns = width > 600 ? 2 : 1
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(columns)), heightDimension: .estimated(300))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))
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
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<NewsSection, NewsItem>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsCell.reuseIdentifier, for: indexPath) as? NewsCell ?? NewsCell()
            cell.configure(with: item)
            cell.applyLayoutMode(.oneColumn)
            
            cell.onFavoriteToggled = { [weak self] in
                self?.viewModel.removeItem(id: item.id)
            }
            
            return cell
        }
    }
    
    private func applySnapshot(with items: [NewsItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<NewsSection, NewsItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let webVC = WebViewController(urlString: item.fullUrl)
        navigationController?.pushViewController(webVC, animated: true)
    }
}
