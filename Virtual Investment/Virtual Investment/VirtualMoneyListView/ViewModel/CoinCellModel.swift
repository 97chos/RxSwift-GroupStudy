//
//  CoinCellModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/29.
//

import Foundation
import RxSwift

class CoinCellViewModel {
  let coin: Coin
  let tickerObservable: Observable<Ticker?>

  init(coin: Coin, tickerObservable: Observable<Ticker?>) {
    self.coin = coin
    self.tickerObservable = tickerObservable
  }
}
