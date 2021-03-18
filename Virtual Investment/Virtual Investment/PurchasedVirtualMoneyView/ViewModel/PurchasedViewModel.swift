//
//  PurchasedViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/04.
//

import Foundation
import RxSwift


class PurchasedViewModel {

  // MARK: Properties

  private let APIService: APIServiceProtocol
  private let bag = DisposeBag()


  

  // MARK: Initializing

  init(APIProtocol: APIServiceProtocol) {
    self.APIService = APIProtocol
  }

  // MARK: Functions

  func getCurrentPrice() -> Completable {
    return Completable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      var coinList: [Coin] = []
      AD.boughtCoins
        .map{ $0.map{ Coin(koreanName: $0.koreanName, englishName: $0.englishName, code: $0.code) } }
        .subscribe(onNext: {
          coinList = $0
        })
        .disposed(by: self.bag)

      if !coinList.isEmpty {
        Observable.combineLatest(self.APIService.loadCoinsTickerDataRx(coins: coinList), AD.boughtCoins)
          .take(1)
          .subscribe(onNext: { tickerData, immutableList in
            var coinList = immutableList
            tickerData.enumerated().forEach{ index, prices in
              coinList[index].prices?.currentPrice = prices.currentPrice
            }
            AD.boughtCoins.accept(coinList)
            observer(.completed)
          }, onError: {
            observer(.error($0))
          })
          .disposed(by: self.bag)
      }
      return Disposables.create()
    }
  }

  func checkProfit(_ investedPrice: Double, _ evaluatedPrice: Double) -> checkProfit {
    if investedPrice > evaluatedPrice {
      return .profit
    } else if investedPrice < evaluatedPrice {
      return .loss
    } else {
      return .equal
    }
  }
}
