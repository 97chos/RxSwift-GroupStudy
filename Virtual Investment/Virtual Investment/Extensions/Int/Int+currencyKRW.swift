//
//  Int+currencyKRW.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/26.
//

import Foundation

extension Int {
  func currenyKRW() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter.string(from: NSNumber(value: self)) ?? ""
  }

  func cutDecimal() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: self)) ?? ""
  }

}
