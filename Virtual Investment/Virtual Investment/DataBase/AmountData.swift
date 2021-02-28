//
//  BalanceData.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation

class AmountData {
  static var shared = AmountData()
  var inputtedDeposit: Double = 0
  var deposit: Double {
    get {
      return inputtedDeposit - boughtCoins.reduce(0){ $0 + $1.totalBoughtPrice}
    }
  }
  var evaluatedPrice: Double = 0
  var investmentAccount: Double = 0
  var boughtCoins: [Coin] = []

  private init() {
  }
}
