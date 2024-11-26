//
//  BrowserToolbarViewController.swift
//  Browser
//
//  Created by Sheen on 11/12/24.
//

import Cocoa
import Combine

class BrowserToolbarViewController: NSViewController {
    
    static let textWidth = 200.0
    static let padding = 10.0
    var interactor: BrowserToolbarViewInteractable?
    
    var textFieldLeadingConstraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()
    private lazy var collectionViewController: TabButtonCollectionViewController = {
        let collectionViewController = TabButtonCollectionViewController()
        collectionViewController.interactor = interactor
        return collectionViewController
    }()

    private(set) lazy var textField: NSTextField = {
        let textField = NSTextField()
        textField.isEditable = true
        textField.bezelStyle = .roundedBezel
        textField.cell?.sendsActionOnEndEditing = true
        textField.target = self
        textField.action = #selector(goToURL(_:))
        return textField
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
        subscribe()
    }
    
    @IBAction func goToURL(_ sender: Any) {
        let urlString = textField.stringValue
        interactor?.openURL(urlString)
    }
    
}

private extension BrowserToolbarViewController {
    func addSubViews() {
        view.addSubview(textField)
        view.addSubview(collectionViewController.view)
    }
    
    func setupConstraints() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        collectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let collectionContainerView = collectionViewController.view
        let textFieldLeadingConstraint =  textField.leadingAnchor.constraint(equalTo: view.centerXAnchor)
        self.textFieldLeadingConstraint = textFieldLeadingConstraint
        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textFieldLeadingConstraint,
            textField.widthAnchor.constraint(equalToConstant: Self.textWidth),
            collectionContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionContainerView.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: Self.padding),
            collectionContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                              constant: -Self.padding),
            collectionContainerView.heightAnchor.constraint(equalToConstant: 32.0)
        ])
    }
        
    func subscribe() {
        interactor?.browserModelPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] buttonVMs in
                guard let self, let textFieldLeadingConstraint else { return }
                view.removeConstraint(textFieldLeadingConstraint)
                let canHideToolbar = buttonVMs.count < 2
                let xAnchor = canHideToolbar ? view.centerXAnchor : view.leadingAnchor
                let valueToAdjust = canHideToolbar ?  -ceil(textField.frame.width/2) : 10
                let leadingConstraint =  textField.leadingAnchor.constraint(equalTo: xAnchor, constant: valueToAdjust)
                self.textFieldLeadingConstraint = leadingConstraint
               
                NSAnimationContext.runAnimationGroup({ [weak self] context in
                   //Indicate the duration of the animation
                    context.duration = 0.25
                    self?.view.animator().addConstraint(leadingConstraint)
                    self?.collectionViewController.view.animator().isHidden = canHideToolbar
                    self?.view.layoutSubtreeIfNeeded()
                  }, completionHandler:nil)
            })
            .store(in: &cancellables)
    }
}
