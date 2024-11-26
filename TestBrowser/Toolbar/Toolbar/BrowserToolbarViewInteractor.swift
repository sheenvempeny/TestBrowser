//
//  BrowserToolbarViewInteractor.swift
//  Browser
//
//  Created by Sheen on 11/15/24.
//

import Foundation
import Combine

protocol BrowserToolbarViewListening {
    func selectTab(identifier: UUID)
    func insertNewTab()
    func removeTab(identifier: UUID)
    func openURL(_ urlString: String)
}

protocol BrowserToolbarViewPublishable {
    var browserModelPublisher: AnyPublisher<[BrowserModel], Never> { get }
    var insertModelPublisher: PassthroughSubject<BrowserModel, Never> { get }
    var removeModelPublisher: PassthroughSubject<BrowserModel, Never> { get }
    var selectedModelPublisher: AnyPublisher<BrowserModel?, Never> { get }
}

typealias BrowserToolbarViewInteractable = BrowserToolbarViewListening & BrowserToolbarViewPublishable

class BrowserToolbarViewInteractor: BrowserToolbarViewInteractable {
    
    let insertModelPublisher = PassthroughSubject<BrowserModel, Never>()
    let removeModelPublisher = PassthroughSubject<BrowserModel, Never>()
    
    var webViewListener: WebTabViewListening
    @Published private var selectedModel: BrowserModel?
    @Published private var tabModels: [BrowserModel] = []
    
    init(webViewListener: WebTabViewListening) {
        self.webViewListener = webViewListener
    }
    
    var browserModelPublisher: AnyPublisher<[BrowserModel], Never> {
        $tabModels.eraseToAnyPublisher()
    }
    
    var selectedModelPublisher: AnyPublisher<BrowserModel?, Never> {
        $selectedModel
            .debounce(for: 0.05, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        selectedModel?.url = url
        if let selectedModel {
            webViewListener.changeURL(to: url, for: selectedModel)
        }
    }

    func insertNewTab() {
        let identifier = UUID()
        let defaultURL = URL(string: "https://www.google.com")
        guard let defaultURL else { return }
        var tabModel = BrowserModel(identifier: identifier)
        tabModel.url = defaultURL
        tabModels.append(tabModel)
        insertModelPublisher.send(tabModel)
        selectedModel = tabModel
    }
    
    func removeTab(identifier: UUID) {
        if let indexToRemove = tabModels.firstIndex(where: { $0.identifier == identifier }) {
            let tabViewModel = tabModels[indexToRemove]
            tabModels.remove(at: indexToRemove)
            removeModelPublisher.send(tabViewModel)
            if selectedModel?.identifier == identifier {
                selectedModel = nil
                if indexToRemove + 1 < tabModels.count {
                    selectedModel = tabModels[indexToRemove + 1]
                } else if indexToRemove - 1 >= 0, indexToRemove - 1 < tabModels.count {
                    selectedModel = tabModels[indexToRemove - 1]
                }
            }
        }
    }
}

// #MARK: BrowserToolbarViewListening
extension BrowserToolbarViewInteractor {
    func selectTab(identifier: UUID) {
        guard let model = tabModels.filter({ $0.identifier == identifier }).first else {
            return
        }
        selectedModel = model
    }
}
