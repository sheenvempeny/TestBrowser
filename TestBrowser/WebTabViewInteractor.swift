//
//  WebTabViewInteractor.swift
//  TestBrowser
//
//  Created by Sheen on 11/21/24.
//

import Foundation
import Combine

enum WebTabViewAction {
    case new(BrowserModel)
    case select(BrowserModel)
    case close(BrowserModel)
}

protocol WebTabViewListening: AnyObject {
    func perform(action: WebTabViewAction)
    func changeURL(to url: URL, for model: BrowserModel)
}

protocol WebTabViewPublishable: AnyObject {
    var actionPublisher: PassthroughSubject<WebTabViewAction, Never> { get }
    var urlChangePublisher: PassthroughSubject<BrowserModel, Never> { get }
}

typealias WebTabViewInteractable = WebTabViewListening & WebTabViewPublishable

class WebTabViewInteractor: WebTabViewInteractable {
    
    var actionPublisher = PassthroughSubject<WebTabViewAction, Never>()
    var urlChangePublisher = PassthroughSubject<BrowserModel, Never>()
    
    func perform(action: WebTabViewAction) {
        actionPublisher.send(action)
    }
    
    func changeURL(to url: URL, for model: BrowserModel) {
        var model = model
        model.url = url
        urlChangePublisher.send(model)
    }
}
