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

  func getCurrentPrice(completion: @escaping (Result<(),Error>) -> Void) {
    let codeList = AmountData.shared.boughtCoins.value.map{ $0.code }
    if !codeList.isEmpty {
      Observable.combineLatest(self.APIService.loadCoinsTickerDataRx(codes: codeList), AmountData.shared.boughtCoins)
        .take(1)
        .subscribe(onNext: { tickerData, immutableList in
          var coinList = immutableList
          tickerData.enumerated().forEach{ index, prices in
            coinList[index].prices?.currentPrice = prices.currentPrice
          }
          AmountData.shared.boughtCoins.accept(coinList)
          completion(.success(()))
        }, onError: {
          completion(.failure($0))
        })
        .disposed(by: bag)
    } else {
      return
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
