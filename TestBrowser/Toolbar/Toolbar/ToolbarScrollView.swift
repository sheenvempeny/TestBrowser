//
//  ToolbarScrollView.swift
//  TestBrowser
//
//  Created by Sheen on 11/23/24.
//

import Cocoa

class ToolbarScrollView: NSScrollView {

    override var hasHorizontalScroller: Bool {
        get {
            false
        }
        set {
            super.hasHorizontalScroller = newValue
        }
    }

    override var horizontalScroller: NSScroller? {
        get {
            nil
        }
        set {
            super.horizontalScroller = newValue
        }
    }
}
