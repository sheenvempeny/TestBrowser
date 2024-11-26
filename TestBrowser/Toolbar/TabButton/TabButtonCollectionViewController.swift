//
//  TabButtonCollectionViewController.swift
//  Browser
//
//  Created by Sheen on 11/12/24.
//

import Cocoa
import Combine

class TabButtonCollectionViewController: NSViewController {
    
    private var lastSelectedItem: IndexPath?
    private var noOfItemsInLastCalculation: Int?
    private var itemSize: ItemSize = .maxium
    static let collectionViewItemIdentifier = NSUserInterfaceItemIdentifier("TabButtonCollectionViewItem")
    var interactor: BrowserToolbarViewInteractable?
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var scrollView: NSScrollView = {
        ToolbarScrollView()
    }()
    
    private lazy var collectionView: NSCollectionView = {
        let collectionView = NSCollectionView()
        collectionView.backgroundColors = [NSColor.clear]
        collectionView.register(TabButtonCollectionViewItem.self,
                                forItemWithIdentifier: Self.collectionViewItemIdentifier)
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = flowLayout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = false
        collectionView.allowsEmptySelection = true
        collectionView.isSelectable = true
        return collectionView
    }()
    
    private var browserModels = [BrowserModel]()
    
    override func loadView() {
        view = NSView()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        subscribe()
    }
    
    var hasTabs: Bool {
        !browserModels.isEmpty
    }
}

private extension TabButtonCollectionViewController {
    
    
    func needsReload(lastItemSize: ItemSize) -> Bool {
        if lastItemSize.isMaximum == true,  lastItemSize.isMaximum == itemSize.isMaximum {
            return false
        }
        if lastItemSize.isMinium == true, lastItemSize.isMinium == itemSize.isMinium {
            return false
        }
        if lastItemSize.isCustom == true,  lastItemSize.isCustom ==  itemSize.isCustom {
            return false
        }
        if lastItemSize.isMaximum == true, lastItemSize.isMaximum == itemSize.isCustom {
            return false
        }
        return true
    }
    
    func setupCollectionView() {
        scrollView.documentView = collectionView
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func updateItemSize() {
        let numberOfItems = browserModels.count
        guard numberOfItems > 1 else {
            itemSize = .maxium
            return
        }
        if let noOfItemsInLastCalculation,
           itemSize.rawValue == ItemSize.minimum.rawValue,
           numberOfItems > noOfItemsInLastCalculation {
            return
        }
        
        let availableVisibleWidth = scrollView.bounds.width
        var newItemSize = ItemSize.maxium.rawValue
        while newItemSize > ItemSize.minimum.rawValue {
            let spacing = 1.0
            let totalSizeRequired: CGFloat = CGFloat(numberOfItems * newItemSize) + (spacing * Double(numberOfItems))
            if totalSizeRequired < availableVisibleWidth {
                break
            }
            newItemSize -= 5
        }
        
        if newItemSize == ItemSize.maxium.rawValue {
            itemSize = .maxium
        } else if newItemSize <= ItemSize.minimum.rawValue {
            itemSize = .minimum
        } else {
            itemSize = .custom(newItemSize)
        }
        noOfItemsInLastCalculation = numberOfItems
    }
    
    
    func subscribe() {
        interactor?.browserModelPublisher
            .first()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] models in
                guard let self else { return }
                browserModels = models
                updateItemSize()
                collectionView.animator().reloadData()
            })
            .store(in: &cancellables)
        
        interactor?.insertModelPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] viewModel in
                guard let self else { return }
                browserModels.append(viewModel)
                let lastItemSize = itemSize
                updateItemSize()
                let isReloadRequired = needsReload(lastItemSize: lastItemSize)
                collectionView.performBatchUpdates({ [weak self] in
                    guard let self else { return }
                    collectionView.insertItems(at: [IndexPath(item: browserModels.count - 1, section: 0)])
                    collectionView.scrollToItems(at: [IndexPath(item: browserModels.count - 1, section: 0)], scrollPosition: .right)
                    if isReloadRequired {
                        collectionView.reloadData()
                    }
                })
            })
            .store(in: &cancellables)
        interactor?.removeModelPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] buttonVM in
                guard let self else { return }
                guard let indexPathForItem = indexPathForItem(with: buttonVM) else {
                    return
                }
                browserModels.remove(at: indexPathForItem.item)
                let lastItemSize = itemSize
                updateItemSize()
                let isReloadRequired = needsReload(lastItemSize: lastItemSize)
                collectionView.performBatchUpdates({ [weak self] in
                    guard let self else { return }
                    collectionView.deleteItems(at: [indexPathForItem])
                    if isReloadRequired {
                        collectionView.reloadData()
                    }
                })
            })
            .store(in: &cancellables)
        interactor?.selectedModelPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] buttonVM in
                guard let self else { return }
                guard let buttonVM else {
                    return
                }
                guard let indexPathForItem = indexPathForItem(with: buttonVM) else {
                    return
                }
                selectIndex(indexPathForItem: indexPathForItem)
            })
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification, object: view)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                collectionView.reloadData()
            }
            .store(in: &cancellables)

    }

    func selectIndex(indexPathForItem: IndexPath) {
        if let lastSelectedItem {
            if lastSelectedItem != indexPathForItem,
                lastSelectedItem.item >= 0, lastSelectedItem.item < browserModels.count {
                collectionView.deselectItems(at: [lastSelectedItem])
                collectionView.reloadItems(at: [lastSelectedItem])
            }
        }
        
        collectionView.reloadItems(at: [indexPathForItem])
        collectionView.animator().performBatchUpdates({ [weak self] in
            guard let self else { return }
            collectionView.selectItems(at: [indexPathForItem], scrollPosition: .trailingEdge)
            lastSelectedItem = indexPathForItem
            collectionView.scrollToItems(at: [indexPathForItem], scrollPosition: .right)
        }, completionHandler: { [weak self] _ in
            guard let self else { return }
            if indexPathForItem.item == browserModels.count - 1 {
                collectionView.scroll(NSPoint(x: NSMaxX(self.collectionView.frame), y: 0))
            }
        })

    }
    
    func clearSelection() {
        if let lastSelectedItem,
            lastSelectedItem.item >= 0,
            lastSelectedItem.item < browserModels.count {
                collectionView.deselectItems(at: [lastSelectedItem])
            collectionView.reloadItems(at: [lastSelectedItem])
        }
        
        lastSelectedItem = nil
    }
    
    func indexPathForItem(with tabButtonModel: BrowserModel) -> IndexPath? {
        var indexPath: IndexPath?
        for index in 0..<collectionView.numberOfItems(inSection: 0) {
            guard let item = collectionView.item(at: IndexPath(item: index, section: 0)) as? TabButtonCollectionViewItem else {
                continue
            }
            if item.representedObject as? BrowserModel == tabButtonModel {
                indexPath = IndexPath(item: index, section: 0)
                break
            }
        }
        return indexPath
    }
}

extension TabButtonCollectionViewController: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return browserModels.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(withIdentifier: Self.collectionViewItemIdentifier,
                                                 for: indexPath) as? TabButtonCollectionViewItem else {
            return NSCollectionViewItem()
        }
        item.tabButtonViewModel = browserModels[indexPath.item]
        item.representedObject = browserModels[indexPath.item]
        let selectedIndex = collectionView.selectionIndexPaths.first?.item
        if indexPath.item == selectedIndex {
            item.currentSize = .maxium
        } else {
            item.currentSize = itemSize
        }
        
        item.closeAction = { [weak self] model in
            guard let self, let model else { return }
            interactor?.removeTab(identifier: model.identifier)
        }
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        let tabButtonViewModel = browserModels[indexPath.item]
        interactor?.selectTab(identifier: tabButtonViewModel.identifier)
    }
}

extension TabButtonCollectionViewController: NSCollectionViewDelegateFlowLayout {
    // Dynamic item size
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let totalHeight = 28.0
        let height: CGFloat = totalHeight // Fixed height for all items
        let selectedIndex = collectionView.selectionIndexPaths.first?.item
        let width = (selectedIndex == indexPath.item) ? CGFloat(ItemSize.maxium.rawValue) : CGFloat(itemSize.rawValue)
        return NSSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return itemSize.rawValue == ItemSize.maxium.rawValue ? 1.0 : 0.5
    }
}
