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
  let tradePrice: Double?

  enum CodingKeys: String, CodingKey {
    case koreanName = "korean_name"
    case englishName = "english_name"
    case code = "market"
    case tradePrice = "tp"
  }
}

struct ticker: Codable {

  // MARK: Json Keys

  let currentPrice: Double
  let code: String

  enum CodingKeys: String, CodingKey {
    case currentPrice = "tp"
    case code = "cd"
  }
}
