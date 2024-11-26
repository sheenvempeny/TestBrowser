//
//  MouseTrackingBox.swift
//  TestBrowser
//
//  Created by Sheen on 11/24/24.
//

import Cocoa
import Combine

protocol MouseTrackingViewProtocol {
    var mouseOverPublisher: AnyPublisher<Bool, Never> { get }
}

class MouseTrackingBox: NSBox, MouseTrackingViewProtocol {
    
    var mouseOverPublisher: AnyPublisher<Bool, Never> {
        $isMouseOverTheView.eraseToAnyPublisher()
    }
    
    @Published private var isMouseOverTheView = false
    
    private lazy var area = makeTrackingArea()
    
    public override func updateTrackingAreas() {
        removeTrackingArea(area)
        area = makeTrackingArea()
        addTrackingArea(area)
    }
    
    public override func mouseEntered(with event: NSEvent) {
        isMouseOverTheView = true
    }
    
    public override func mouseExited(with event: NSEvent) {
        isMouseOverTheView = false
    }
    
    private func makeTrackingArea() -> NSTrackingArea {
        return NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow], owner: self, userInfo: nil)
    }
    
    deinit {
        removeTrackingArea(area)
    }
}
