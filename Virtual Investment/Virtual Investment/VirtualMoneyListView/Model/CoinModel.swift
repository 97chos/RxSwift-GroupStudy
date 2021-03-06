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

  enum CodingKeys: String, CodingKey {
    case koreanName = "korean_name"
    case englishName = "english_name"
    case code = "market"
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

