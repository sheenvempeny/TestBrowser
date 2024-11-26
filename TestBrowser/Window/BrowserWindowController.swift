//
//  BrowserWindowController.swift
//  Browser
//
//  Created by Sheen on 11/12/24.
//

import Cocoa
import Combine

class BrowserWindowController: NSWindowController {
    
    @IBOutlet private var tabsContainer: NSView!
    var cancellables = Set<AnyCancellable>()
    let webTabViewInteractor = WebTabViewInteractor()
    
    private lazy var browserToolbarViewController: BrowserToolbarViewController = {
        var browserToolbarViewController = BrowserToolbarViewController()
        var interactor = BrowserToolbarViewInteractor(webViewListener: webTabViewInteractor)
        browserToolbarViewController.interactor = interactor
        return browserToolbarViewController
    }()
    
    private lazy var webTabViewController: WebTabViewController? = {
        guard let webTabViewController = window?.contentViewController
                as? WebTabViewController else {
            return nil
        }
        webTabViewController.interactor = webTabViewInteractor
        return webTabViewController
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        addSubViews()
        setConstraints()
        subscribe()
        browserToolbarViewController.interactor?.insertNewTab()
    }
    
    @IBAction func addNewTab(_ sender: Any) {
        browserToolbarViewController.interactor?.insertNewTab()
    }
}

private extension BrowserWindowController {
    
    func addSubViews() {
        browserToolbarViewController.view.frame = tabsContainer.bounds
        tabsContainer.addSubview(browserToolbarViewController.view)
    }
    
    func setConstraints() {
        browserToolbarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            browserToolbarViewController.view.bottomAnchor.constraint(equalTo: tabsContainer.bottomAnchor),
            browserToolbarViewController.view.trailingAnchor.constraint(equalTo: tabsContainer.trailingAnchor),
            browserToolbarViewController.view.leadingAnchor.constraint(equalTo: tabsContainer.leadingAnchor),
            browserToolbarViewController.view.topAnchor.constraint(equalTo: tabsContainer.topAnchor)
        ])
    }
    
    func subscribe() {
        let insertModelPublisher = browserToolbarViewController.interactor?.insertModelPublisher
        insertModelPublisher?.sink { [weak self] viewModel in
            guard let self else { return }
            let action = WebTabViewAction.new(viewModel)
            webTabViewController?.interactor?.perform(action: action)
        }
        .store(in: &cancellables)
        let selectedModelPublisher = browserToolbarViewController.interactor?.selectedModelPublisher
        selectedModelPublisher?.sink { [weak self] viewModel in
            guard let self, let viewModel else { return }
            let action = WebTabViewAction.select(viewModel)
            webTabViewController?.interactor?.perform(action: action)
        }
        .store(in: &cancellables)
        let removeModelPublisher = browserToolbarViewController.interactor?.removeModelPublisher
        removeModelPublisher?.sink { [weak self] viewModel in
            guard let self else { return }
            let action = WebTabViewAction.close(viewModel)
            webTabViewController?.interactor?.perform(action: action)
        }
        .store(in: &cancellables)
    }
    
}

