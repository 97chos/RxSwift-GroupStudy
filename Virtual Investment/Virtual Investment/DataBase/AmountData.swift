//
//  BalanceData.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation

class AmountData {
  static var shared = AmountData()
  var deposit: Double = 0
  var evaluatedPrice: Double = 0
  var investmentAccount: Double = 0
  var investededCoins: [Coin] = []

  private init() {
  }
}
