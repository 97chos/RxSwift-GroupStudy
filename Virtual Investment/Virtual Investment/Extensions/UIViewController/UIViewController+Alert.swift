//
//  UIViewController+Alert.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/26.
//

import Foundation
import UIKit

extension UIViewController {

  func alert(title: String?, message: String?, completion: (() -> Void)? ) {
    DispatchQueue.main.async {
      let alert: UIAlertController = {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        return alert
      }()

      guard let title = title else { return }

      if title.hasSuffix("?") {
        alert.addAction(UIAlertAction(title: "확인", style: .default){ _ in completion?() })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
      } else {
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
      }

      self.present(alert, animated: true)
    }
  }
}
