//
//  Double+cutDecimal.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/27.
//

import Foundation

extension Double {
  func cutDecimal() -> String {
    if self > 1 {
      let numberFormatter = NumberFormatter()
      numberFormatter.numberStyle = .decimal
      numberFormatter.maximumFractionDigits = 4
      return numberFormatter.string(from: NSNumber(value: self)) ?? ""
    } else {
      return String(format: "%.8f", self)
    }
  }
  
  func currenyKRW() -> String {
    let formatter = NumberFormatter()
    if self > 100 {
      formatter.numberStyle = .currency
      formatter.locale = Locale(identifier: "ko_KR")
      return formatter.string(from: NSNumber(value: self)) ?? ""
    } else {
      return "₩\(self.cutDecimal())"
    }
  }
}
