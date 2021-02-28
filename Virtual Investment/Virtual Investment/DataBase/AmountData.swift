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
  var investedPrice: Double{
    get {
      return boughtCoins.reduce(0){ $0 + $1.totalBoughtPrice}
    }
  }
  var boughtCoins: [Coin] = []

  func getEvaluatedPrice() -> Double {
    var price: Double = 0
    boughtCoins.forEach {
      var coin = $0
      price += Double(coin.holdingCount) * (coin.prices?.currentPrice ?? 0)
    }
    return price
  }

  private init() {
  }
}
