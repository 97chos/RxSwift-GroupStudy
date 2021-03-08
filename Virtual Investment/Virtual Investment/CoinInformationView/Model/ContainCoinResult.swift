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
  init (_ boolean: Bool, _ coin: Coin?) {
    self.isResult = boolean
    self.coin = coin
  }
}

extension ContainCoinResult: Equatable {
  static func == (lhs: ContainCoinResult, rhs: ContainCoinResult) -> Bool {
    return lhs.isResult == rhs.isResult
  }
}
