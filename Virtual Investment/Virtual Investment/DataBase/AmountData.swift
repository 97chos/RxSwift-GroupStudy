//
//  BalanceData.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation

class BalanceData {
  static var shared = BalanceData()
  var balance: Int = 0
  var evaluadtedPrice: Float = 0
  var investmentAmount: Float = 0

  private init() {
  }
}
