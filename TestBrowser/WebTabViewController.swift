//
//  ViewController.swift
//  TestBrowser
//
//  Created by Sheen on 11/19/24.
//

import Cocoa
import Combine

class WebTabViewController: NSViewController {

    @IBOutlet weak var tabView: NSTabView!
    
    var cancellables = Set<AnyCancellable>()
    var interactor: WebTabViewInteractable? {
        didSet {
            cancellables.removeAll()
            subscribe()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

private extension WebTabViewController {
    
    func subscribe() {
        interactor?.actionPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            
            case .new(let model):
                let interactor = BrowserTabItemViewInteractor(viewModel: model)
                let browserTabItemVC = BrowserTabItemViewController()
                browserTabItemVC.interactor = interactor
                let tabViewItem = NSTabViewItem(viewController: browserTabItemVC)
                tabViewItem.identifier = model.identifier
                tabView.animator().addTabViewItem(tabViewItem)
            case .select(let model):
                tabView.animator().selectTabViewItem(withIdentifier: model.identifier)
            case .close(let model):
                guard let tabItemToClose = tabView.tabViewItems.first(where: { $0.identifier as? UUID ==  model.identifier }) else {
                    return
                }
                tabView.animator().removeTabViewItem(tabItemToClose)
            }
        }
        .store(in: &cancellables)
        
        interactor?.urlChangePublisher.sink { [weak self] model in
            guard let self, let url = model.url else { return }
            let selectedTab = tabView.selectedTabViewItem
            guard let vc = selectedTab?.viewController as? BrowserTabItemViewController else { return }
            vc.interactor?.openURL(url)
        }
        .store(in: &cancellables)
        
    }
}

