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
      var codeList: [String] = []
      AmountData.shared.boughtCoins
        .map{ $0.map{ $0.code } }
        .subscribe(onNext: {
          codeList = $0
        })
        .disposed(by: self.bag)

      if !codeList.isEmpty {
        Observable.combineLatest(self.APIService.loadCoinsTickerDataRx(codes: codeList), AmountData.shared.boughtCoins)
          .take(1)
          .subscribe(onNext: { tickerData, immutableList in
            var coinList = immutableList
            tickerData.enumerated().forEach{ index, prices in
              coinList[index].prices?.currentPrice = prices.currentPrice
            }
            AmountData.shared.boughtCoins.accept(coinList)
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
