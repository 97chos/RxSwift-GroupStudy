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


  // MARK: Initializing

  init(APIProtocol: APIServiceProtocol) {
    self.APIService = APIProtocol
  }

  // MARK: Functions

  func getCurrentPrice(completion: @escaping (Result<(),Error>) -> Void) {
    let codeList = AmountData.shared.boughtCoins.value.map{ $0.code }
    if !codeList.isEmpty {
      self.APIService.loadCoinsTickerData(codes: codeList) { result in
        switch result {
        case .success(let coinPriceList):
          var copyCoinList = AmountData.shared.boughtCoins.value
          coinPriceList.enumerated().forEach { index, prices in
            copyCoinList[index].prices?.currentPrice = prices.currentPrice
          }
          AmountData.shared.boughtCoins.accept(copyCoinList)
          completion(.success(()))

        case .failure(let error):
          completion(.failure(error))
        }
      }
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
