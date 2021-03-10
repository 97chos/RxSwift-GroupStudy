//
//  SectionItems.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/05.
//

import Foundation
import RxDataSources

struct CoinListSection {
  var header: String
  var items: [Item]
}

extension CoinListSection: AnimatableSectionModelType {
  typealias Item = Coin

  var identity: String {
    return header
  }

  init(original: CoinListSection, items: [Item]) {
      self = original
      self.items = items
  }
}


struct MySection {
    var header: String
    var items: [Item]
}

extension MySection : AnimatableSectionModelType {
    typealias Item = Int

    var identity: String {
        return header
    }

    init(original: MySection, items: [Item]) {
        self = original
        self.items = items
    }
}
