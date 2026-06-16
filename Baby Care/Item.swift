//
//  Item.swift
//  Baby Care
//
//  Created by ouzkrcn on 17.06.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
