//
//  CoinModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import RxDataSources

struct Coin: Codable {

  // MARK: Json Keys

  let koreanName: String
  let englishName: String
  let code: String
  var prices: ticker?
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

extension Coin: Equatable, Hashable {
  static func == (lhs: Coin, rhs: Coin) -> Bool {
    return lhs.code == rhs.code && lhs.koreanName == rhs.koreanName && lhs.englishName == rhs.englishName
  }
}

extension Coin: IdentifiableType {
  var identity: String {
    return self.code
  }

  typealias Identity = String
}

struct ticker: Codable, Hashable {

  // MARK: Json Keys

  var currentPrice: Double
  let code: String
  let highPrice: Double
  let lowPrice: Double

  enum CodingKeys: String, CodingKey {
    case currentPrice = "tp"
    case code = "cd"
    case highPrice = "hp"
    case lowPrice = "lp"
  }
}

struct APITicker: Codable, Hashable {
  let code: String
  let currentPrice: Double
  let highPrice: Double
  let lowPrice: Double

  enum CodingKeys: String, CodingKey {
    case code = "market"
    case currentPrice = "tradePrice"
    case highPrice = "high_Price"
    case lowPrice = "low_Price"
  }
}
