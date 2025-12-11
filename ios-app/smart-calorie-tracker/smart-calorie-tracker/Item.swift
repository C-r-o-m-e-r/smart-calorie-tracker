//
//  Item.swift
//  smart-calorie-tracker
//
//  Created by Орест Романюк on 11.12.2025.
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
