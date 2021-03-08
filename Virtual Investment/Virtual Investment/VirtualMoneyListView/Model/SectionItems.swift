//
//  SectionItems.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/05.
//

import Foundation
import RxDataSources

struct CoinListSection {
  var items: [Item]

  init(original: CoinListSection, items: [Coin]) {
    self.items = items
  }
  init(items: [Coin]) {
    self.items = items
  }
}

extension CoinListSection: SectionModelType {

  var identity: Identity {
    return Int.random(in: 0...100000)
  }

  typealias Item = Coin
  typealias Identity = Int
}
