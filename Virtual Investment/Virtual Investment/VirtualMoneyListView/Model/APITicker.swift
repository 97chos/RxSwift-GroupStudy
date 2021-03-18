//
//  APITicker.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/18.
//

import Foundation

struct APITicker: Decodable, Hashable {
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
