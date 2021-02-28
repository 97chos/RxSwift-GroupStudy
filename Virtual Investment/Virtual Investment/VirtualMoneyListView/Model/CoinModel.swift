//
//  CoinModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation

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

struct ticker: Codable {

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
