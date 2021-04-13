//
//  CoinModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/17.
//

import Foundation
import RxDataSources
import CoreData

struct CoinInfo: Codable {

  // MARK: Json Keys

  let koreanName: String
  let englishName: String
  let code: String
  var totalBoughtPrice: Double
  var holdingCount: Int {
    didSet {
      if holdingCount == 0 {
        self.totalBoughtPrice = 0
      }
    }
  }
  var prices: Ticker?
  var objectID: NSManagedObjectID?

  enum CodingKeys: String, CodingKey {
    case koreanName = "korean_name"
    case englishName = "english_name"
    case code = "market"
    case totalBoughtPrice
    case holdingCount
    case prices
  }
}

extension CoinInfo: Equatable, Hashable {
  static func == (lhs: CoinInfo, rhs: CoinInfo) -> Bool {
    return lhs.code == rhs.code && lhs.koreanName == rhs.koreanName && lhs.englishName == rhs.englishName
  }
}

extension CoinInfo {
  init(coin: Coin, ticker: Ticker?) {
    self.init(
      koreanName: coin.koreanName,
              englishName: coin.englishName,
      code: coin.code,
      totalBoughtPrice: 0,
      holdingCount: 0,
      prices: ticker,
      objectID: nil
    )
  }
}
