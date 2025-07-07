//
//  HistoryItem.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//

import Foundation
import SwiftUI

struct HistoryItem: Codable, Identifiable {
    var id: UUID = .init()
    let value: String
    let date: Date
}
