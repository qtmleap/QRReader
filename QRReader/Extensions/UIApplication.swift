//
//  UIApplication.swift
//  QRReader
//
//  Created by devonly on 2025/07/08.
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
