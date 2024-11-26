//
//  ItemSize.swift
//  TestBrowser
//
//  Created by Sheen on 11/25/24.
//

import Foundation

enum ItemSize {
    case maxium
    case custom(Int)
    case minimum
    
    var rawValue: Int {
        switch self {
        case .maxium:
            return 120
        case .custom(let value):
            return value
        case .minimum:
            return 50
        }
    }
    
    var isMaximum: Bool {
        switch self {
        case .maxium:
            return true
        case .custom, .minimum:
            return false
        }
    }
    
    var isMinium: Bool {
        switch self {
        case .minimum:
            return true
        case .custom, .maxium:
            return false
        }
    }

    var isCustom: Bool {
        return (!isMaximum && !isMinium)
    }
}
