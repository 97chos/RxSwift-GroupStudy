//
//  BalanceData.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation

class AmountData {
  static var shared = AmountData()
  var deposit: Float = 0
  var evaluatedPrice: Float = 0
  var investmentAccount: Float = 0
  var investededCoins: [Coin] = []

  private init() {
  }
}
