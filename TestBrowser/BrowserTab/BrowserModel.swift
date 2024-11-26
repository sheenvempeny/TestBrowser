//
//  BrowserModel.swift
//  TestBrowser
//
//  Created by Sheen on 11/19/24.
//

import Foundation
import Cocoa

struct BrowserModel: Hashable {
    let identifier: UUID
    var displayName: String {
        if let url {
            return url.host ?? ""
        }
        return ""
    }
    var image: NSImage?
    var url: URL?
    
    init(identifier: UUID) {
        self.identifier = identifier
    }
    
    static func == (lhs: BrowserModel, rhs: BrowserModel) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
}
