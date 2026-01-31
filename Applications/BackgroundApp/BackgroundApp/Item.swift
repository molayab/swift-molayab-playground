//
//  Item.swift
//  BackgroundApp
//
//  Created by Mateo Olaya on 1/30/26.
//

import Foundation
import SwiftData

@Model
final class Item: Sendable {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
