//
//  PurchasedViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/04.
//

import Foundation
import RxSwift


class PurchasedViewModel {

  // MARK: Modules

  struct Input {
    let didInitialized = PublishSubject<Void>()
    let connectWebSocket = PublishSubject<Void>()
    let disConnectWebSocket = PublishSubject<Void>()
  }

  struct Output {
    let coinCellViewModel: Observable<[CoinCellViewModel]>
  }


  // MARK: Properties

  private let APIService: CoinServiceProtocol
  private let bag = DisposeBag()


  // MARK: Initializing

  init(APIProtocol: CoinServiceProtocol) {
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
        Observable.combineLatest(self.APIService.tickerList(coins: coinList).asObservable(), AD.boughtCoins)
          .take(1)
          .map{ tickerData, immutableList -> [CoinInfo] in
            var coinList = immutableList
            tickerData.enumerated().forEach{ index, prices in
              coinList[index].prices?.currentPrice = prices.currentPrice
            }
            return coinList
          }
          .observe(on: MainScheduler.asyncInstance)
          .subscribe(onNext: {
            AD.boughtCoins.accept($0)
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
