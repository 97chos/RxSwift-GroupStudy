//
//  CoinModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/17.
//

import Foundation
import RxDataSources

struct CoinInfo: Codable {

  // MARK: Json Keys

  let koreanName: String
  let englishName: String
  let code: String
  var prices: Ticker?
  lazy var holdingCount: Int = 0 {
    didSet {
      if holdingCount == 0 {
        self.totalBoughtPrice = 0
      }
    }
  }
  var totalBoughtPrice: Double = 0

  enum CodingKeys: String, CodingKey {
    case koreanName = "korean_name"
    case englishName = "english_name"
    case code = "market"
    case prices
  }
}

extension CoinInfo: Equatable, Hashable {
  static func == (lhs: CoinInfo, rhs: CoinInfo) -> Bool {
    return lhs.code == rhs.code && lhs.koreanName == rhs.koreanName && lhs.englishName == rhs.englishName
  }
}

extension CoinInfo: IdentifiableType {
  var identity: String {
    return self.code
  }

  typealias Identity = String
}

