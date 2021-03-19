//
//  BalanceData.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import RxSwift
import RxCocoa

let AD = AmountData.shared

class AmountData {
  static var shared = AmountData()
  var deposit: BehaviorRelay = BehaviorRelay<Double>(value: 0)
  var boughtCoins: BehaviorRelay<[CoinInfo]> = BehaviorRelay<[CoinInfo]>(value: [])

  lazy var investedPrice: Observable<Double> = boughtCoins
    .map{ $0.reduce(0){$0 + $1.totalBoughtPrice}}

  lazy var evaluatedPrice: Observable<Double> = boughtCoins
    .map{
      $0.reduce(0){
        var coin = $1
        return $0 + (coin.prices?.currentPrice ?? 0) * Double(coin.holdingCount)
      }
    }

  private init() {
  }
}


