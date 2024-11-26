//
//  TabButtonViewController.swift
//  Browser
//
//  Created by Sheen on 11/16/24.
//

import Cocoa
import Combine

class TabButtonCollectionViewItem: NSCollectionViewItem {
   
    @IBOutlet weak var box: MouseTrackingBox!
    @IBOutlet weak var webIcon: NSImageView!
    @IBOutlet weak var webIconBig: NSImageView!
    @IBOutlet weak var closeButton: NSButton!
    private var cancellables = Set<AnyCancellable>()
    
    var currentSize: ItemSize = .maxium {
        didSet {
            updateConstaints()
        }
    }
    
    override func prepareForReuse() {
        box.fillColor = .clear
        closeButton.isHidden = true
        super.prepareForReuse()
    }
    
    override var isSelected: Bool {
        didSet {
            box.updateTrackingAreas()
            box.fillColor = isSelected ? .gray.withAlphaComponent(0.5) : .clear
            if isSelected {
                currentSize = .maxium
            }
        }
    }
    
    var closeAction: ((BrowserModel?) -> Void)?
    
    var tabButtonViewModel: BrowserModel? {
        didSet {
            textField?.stringValue = tabButtonViewModel?.displayName ?? ""
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.isHidden = true
        subscribe()
    }
    
    @IBAction func closeTab(sender: AnyObject) {
        closeAction?(tabButtonViewModel)
    }
}

private extension TabButtonCollectionViewItem {
       
    func updateConstaints() {
        webIconBig.isHidden = !currentSize.isMinium
        webIcon.isHidden = currentSize.isMinium
        textField?.isHidden = currentSize.isMinium
        if currentSize.isMinium {
            closeButton.isHidden = true
        }
    }
    
    func subscribe() {
        box.mouseOverPublisher.sink { [weak self] isMouseOver in
            guard let self, isSelected else { return }
            webIcon.isHidden = isMouseOver
            closeButton.isHidden = !isMouseOver
        }
        .store(in: &cancellables)
    }
}
