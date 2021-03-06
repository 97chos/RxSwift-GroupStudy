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
    self = original
  }

  init(items: [Coin]) {
    self.items = items
  }
}

extension CoinListSection: AnimatableSectionModelType {

  var identity: String {
    return ReuseIdentifier.coinListCell
  }

  typealias Item = Coin
}
