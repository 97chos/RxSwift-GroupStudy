//
//  ContainCoinResult.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/08.
//

import Foundation

struct ContainCoinResult {
  var isResult: Bool
  var coin: Coin?
  var currentCoin: Coin
  init (_ boolean: Bool, _ coin: Coin?, _ currentCoin: Coin) {
    self.isResult = boolean
    self.coin = coin
    self.currentCoin = currentCoin
  }
}

extension ContainCoinResult: Equatable {
  static func == (lhs: ContainCoinResult, rhs: ContainCoinResult) -> Bool {
    return lhs.isResult == rhs.isResult
  }
}
