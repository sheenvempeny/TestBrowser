//
//  BrowserTabItemViewInteractor.swift
//  TestBrowser
//
//  Created by Sheen on 11/19/24.
//

import Foundation
import Combine

protocol BrowserTabViewListening {
    func titleChanged(_ title: String)
}

protocol BrowserTabItemViewInteractable {
    var newURLPublisher: PassthroughSubject<URL, Never> { get }
    var browserViewModel: BrowserModel { get }
    init (viewModel: BrowserModel)
    func openURL(_ url: URL)
}

class BrowserTabItemViewInteractor: BrowserTabItemViewInteractable {
    var newURLPublisher = PassthroughSubject<URL, Never>()
    var cancellables = Set<AnyCancellable>()
    private(set) var browserViewModel: BrowserModel
    
    required init (viewModel: BrowserModel) {
        self.browserViewModel = viewModel
    }
    
    func openURL(_ url: URL) {
        newURLPublisher.send(url)
    }
}
extension BrowserTabItemViewInteractor: BrowserTabViewListening {
    func titleChanged(_ title: String) {
       // browserViewModel.displayName = title
    }
}
