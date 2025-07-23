//
//  AppStorage.swift
//  QRReader
//
//  Created by devonly on 2025/07/08.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import Foundation

/**
 Array<:Codable>型やDate型をUserDefaultsなどの永続化ストレージで保存・復元できるようにするためのRawRepresentable拡張。

 ## 概要
 - Array<:Codable>型をJSON文字列として保存・復元できるようにします。
 - Date型をISO8601形式の文字列として保存・復元できるようにします。
 - Swiftの@AppStorageやUserDefaultsなど、RawRepresentableに準拠した型であればシームレスに利用可能です。

 ## 使い方
 ```swift
 // 例: UserDefaultsでArrayやDateを保存・取得
 @AppStorage("history") var history: [HistoryItem] = []
 @AppStorage("lastAccess") var lastAccess: Date = Date()
 ```

 ## 注意点
 - DateのISO8601DateFormatterはスレッドセーフではないため、毎回インスタンスを生成しています。
 - ArrayのElementはCodableに準拠している必要があります。
 */

extension Array: @retroactive RawRepresentable where Element: Codable {
    /// JSON文字列からArrayを復元します。
    /// - Parameter rawValue: JSON文字列
    /// - Returns: 復元されたArray、失敗時はnil
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8) else {
            return nil
        }
        do {
            let result = try JSONDecoder().decode([Element].self, from: data)
            self = result
        } catch {
            print(error)
            return nil
        }
    }

    /// ArrayをJSON文字列に変換します。
    /// - Returns: JSON文字列
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

/// Date型をRawRepresentableに拡張し、UserDefaultsや@AppStorageでISO8601文字列として保存・復元できるようにします。
/// - Note: ISO8601DateFormatterはスレッドセーフではないため、毎回インスタンスを生成しています。
/// - SeeAlso: [ISO8601DateFormatter](https://developer.apple.com/documentation/foundation/iso8601dateformatter)
extension Date: @retroactive RawRepresentable {
    /// DateをISO8601形式の文字列に変換します。
    /// - Returns: ISO8601形式の文字列
    public var rawValue: String {
        ISO8601DateFormatter().string(from: self)
    }

    /// ISO8601形式の文字列からDateを復元します。
    /// - Parameter rawValue: ISO8601形式の文字列
    /// - Returns: 復元されたDate、失敗時は現在時刻
    public init?(rawValue: String) {
        self = ISO8601DateFormatter().date(from: rawValue) ?? Date()
    }
}
