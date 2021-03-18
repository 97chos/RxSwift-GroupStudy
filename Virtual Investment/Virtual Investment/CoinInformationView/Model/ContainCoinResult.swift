//
//  ContainCoinResult.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/08.
//

import Foundation

struct ContainCoinResult {
  var isResult: Bool
  var indexCoin: CoinInfo?
  var currentCoin: CoinInfo
  init (_ boolean: Bool, _ coin: CoinInfo?, _ currentCoin: CoinInfo) {
    self.isResult = boolean
    self.indexCoin = coin
    self.currentCoin = currentCoin
  }
}

extension ContainCoinResult: Equatable {
  static func == (lhs: ContainCoinResult, rhs: ContainCoinResult) -> Bool {
    return lhs.isResult == rhs.isResult
  }
}
