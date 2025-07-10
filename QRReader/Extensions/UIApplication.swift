//
//  UIApplication.swift
//  QRReader
//
//  Created by devonly on 2025/07/08.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    var presentedViewController: UIViewController? {
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            var controller = rootViewController
            while let presentedViewController = controller.presentedViewController {
                controller = presentedViewController
            }
            return controller
        }
        return nil
    }
}
