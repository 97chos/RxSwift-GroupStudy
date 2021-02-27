//
//  Double+cutDecimal.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/27.
//

import Foundation

extension Double {
  func cutDecimal() -> String {
    if self > 100 {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      return formatter.string(from: NSNumber(value: self)) ?? ""
    } else {
      return "\(self)"
    }
  }
  
  func currenyKRW() -> String {
    let formatter = NumberFormatter()
    if self > 100 {
      formatter.numberStyle = .currency
      formatter.locale = Locale(identifier: "ko_KR")
      return formatter.string(from: NSNumber(value: self)) ?? ""
    } else {
      return "₩\(self)"
    }
  }
}
