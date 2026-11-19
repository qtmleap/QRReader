//
//  HistoryItem.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import Foundation

struct HistoryItem: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = .init()
    let value: String
    let date: Date
}
