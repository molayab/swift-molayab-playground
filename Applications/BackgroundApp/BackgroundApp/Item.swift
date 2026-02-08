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
    var createdAt: Date = Date()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
