//
//  InvestedCoinCell.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/28.
//

import Foundation
import UIKit
import SnapKit

class InvestedCoinCell: UITableViewCell {

  // MARK: UI

  private let nameLabel: UILabel = {
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 15)
    return label
  }()
  private let holdingCountLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 13)
    return label
  }()
  private let currentPriceLabel: UILabel = {
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 15)
    return label
  }()
  private let evaluatedPriceLabel: UILabel = {
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 15)
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
    var coin = coinData
    let evalutatedPrice = (coin.prices?.currentPrice ?? 0) * Double(coin.holdingCount)
    self.nameLabel.text = "\(coin.koreanName)(\(coin.code))"
    self.holdingCountLabel.text = "보유 수량 : \(coin.holdingCount)"
    self.currentPriceLabel.text = "\(coin.totalBoughtPrice)"
    self.evaluatedPriceLabel.text = "\(evalutatedPrice)"

    if coin.totalBoughtPrice > evalutatedPrice {
      self.evaluatedPriceLabel.textColor = .systemBlue
    } else if coin.totalBoughtPrice < evalutatedPrice {
      self.evaluatedPriceLabel.textColor = .systemRed
    } else {
      self.evaluatedPriceLabel.textColor = .black
    }
  }


  // MARK: Layout

  private func layout() {

    self.contentView.addSubview(self.nameLabel)
    self.contentView.addSubview(self.holdingCountLabel)
    self.contentView.addSubview(self.currentPriceLabel)
    self.contentView.addSubview(self.evaluatedPriceLabel)

    self.nameLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(-15)
      $0.leading.equalToSuperview().inset(10)
    }
    self.holdingCountLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(15)
      $0.leading.equalToSuperview().inset(10)
    }
    self.currentPriceLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(-15)
      $0.trailing.equalToSuperview().inset(10)
    }
    self.evaluatedPriceLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(15)
      $0.trailing.equalToSuperview().inset(10)
    }
  }
}
