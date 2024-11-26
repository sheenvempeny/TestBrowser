//
//  BrowserTabItemViewController.swift
//  TestBrowser
//
//  Created by Sheen on 11/19/24.
//

import Cocoa
import WebKit
import Combine

class BrowserTabItemViewController: NSViewController {
    
    var interactor: (BrowserTabItemViewInteractable & BrowserTabViewListening)?
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var webView: WKWebView = {
        var webView = WKWebView()
        webView.navigationDelegate = self
        return webView
    }()
    
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
        addSubViews()
        setupConstraints()
        oberve()
        subscribe()
        if let url = interactor?.browserViewModel.url {
            webView.load(URLRequest(url: url))
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "title")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title", let title = webView.title {
            print(title)
        }
    }
}

private extension BrowserTabItemViewController {
    func addSubViews() {
        view.addSubview(webView)
    }
    
    func setupConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
    }
    
    func oberve() {
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    }
    
    func subscribe() {
        interactor?.newURLPublisher
            .sink { [weak self] url in
                guard let self else { return }
                webView.load(URLRequest(url: url))
            }
            .store(in: &cancellables)
    }
}

extension BrowserTabItemViewController: WKNavigationDelegate {
    
    
}
