//
//  Ticker.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/18.
//

import Foundation

struct Ticker: Codable, Hashable {

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

extension Ticker {
  init(apiTicker: APITicker) {
    self.currentPrice = apiTicker.currentPrice
    self.code = apiTicker.code
    self.highPrice = apiTicker.highPrice
    self.lowPrice = apiTicker.lowPrice
  }
}
