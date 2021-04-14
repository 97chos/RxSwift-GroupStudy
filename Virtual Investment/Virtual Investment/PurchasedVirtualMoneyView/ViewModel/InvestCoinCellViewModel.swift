//
//  InvestCoinCellViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/04/15.
//

import Foundation
import RxSwift

class InvestCoinCellViewModel {
  var coin: CoinInfo
  let tickerObservable: Observable<Ticker?>

  init(coin: CoinInfo, tickerObservable: Observable<Ticker?>) {
    self.coin = coin
    self.tickerObservable = tickerObservable
  }
}
