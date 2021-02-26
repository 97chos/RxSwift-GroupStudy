//
//  CoinCell.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import UIKit
import SnapKit

class CoinCell: UITableViewCell {

  // MARK: Properties

  private var code: String!

  // MARK: UI

  private let koreanName: UILabel = {
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 15)
    return label
  }()
  private let englishName: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 13)
    return label
  }()
  private let currentPrice: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 15)
    return label
  }()


  // MARK: Initializing

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.layout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: Set

  func set(coinData: Coin) {
    self.koreanName.text = coinData.koreanName
    self.englishName.text = coinData.englishName
    self.code = coinData.code
    if let price = coinData.prices {
      self.currentPrice.text = Int(price.currentPrice).cutDecimal()
    }

    self.koreanName.sizeToFit()
    self.englishName.sizeToFit()
    self.currentPrice.sizeToFit()
  }


  // MARK: Layout

  private func layout() {
    self.contentView.addSubview(self.koreanName)
    self.contentView.addSubview(self.englishName)
    self.contentView.addSubview(self.currentPrice)

    self.koreanName.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(-10)
      $0.leading.equalToSuperview().inset(10)
    }
    self.englishName.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(10)
      $0.leading.equalTo(self.koreanName.snp.leading)
    }
    self.currentPrice.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.trailing.equalToSuperview().inset(10)
    }
  }

  // MARK: Prepare Set

  override func prepareForReuse() {
    self.currentPrice.text = nil
  }
}

