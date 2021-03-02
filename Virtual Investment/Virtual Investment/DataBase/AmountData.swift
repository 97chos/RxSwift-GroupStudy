//
//  BalanceData.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import RxSwift
import RxCocoa

class AmountData {
  static var shared = AmountData()
  var deposit: BehaviorSubject = BehaviorSubject<Double>(value: 0)
  var boughtCoins: BehaviorRelay<[Coin]> = BehaviorRelay<[Coin]>(value: [])

  lazy var investedPrice: Observable<Double> = boughtCoins
    .map{ $0.reduce(0){$0 + $1.totalBoughtPrice}}

  lazy var evaluatedPrice: Observable<Double> = boughtCoins
    .map{
      var price: Double = 0
      $0.forEach{
        var coin = $0
        price += Double(coin.holdingCount) * (coin.prices?.currentPrice ?? 0)
      }
      return price
    }

//  func getEvaluatedPrice() -> Double {
//    var price: Double = 0
//    boughtCoins.forEach {
//      var coin = $0
//      price += Double(coin.holdingCount) * (coin.prices?.currentPrice ?? 0)
//    }
//    return price
//  }

  private init() {
  }
}
