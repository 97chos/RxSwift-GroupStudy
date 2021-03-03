//
//  InvestedCoinCell.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/28.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

class InvestedCoinCell: UITableViewCell {

  // MARK: Properties

  let bag = DisposeBag()

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
  private let totalBoughtPriceLabel: UILabel = {
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

  func set(coinIndex: Int) {
    AmountData.shared.boughtCoins
      .filter{ !$0.isEmpty }
      .map{ $0[coinIndex] }
      .map{ "\($0.koreanName) (\($0.englishName))" }
      .bind(to: self.nameLabel.rx.text)
      .disposed(by: bag)

    AmountData.shared.boughtCoins
      .filter{ !$0.isEmpty }
      .map{ $0[coinIndex] }
      .map{ var coin = $0
        return "보유 수량 : \(coin.holdingCount)"
      }
      .bind(to: self.holdingCountLabel.rx.text)
      .disposed(by: bag)

    AmountData.shared.boughtCoins
      .filter{ !$0.isEmpty }
      .map{ $0[coinIndex]}
      .map{ "\($0.totalBoughtPrice)" }
      .bind(to: self.totalBoughtPriceLabel.rx.text)
      .disposed(by: bag)

    AmountData.shared.boughtCoins
      .filter{ !$0.isEmpty }
      .map{ $0[coinIndex] }
      .map{ var coin = $0
        return "\((coin.prices?.currentPrice ?? 0) * Double(coin.holdingCount))"
      }
      .bind(to: self.evaluatedPriceLabel.rx.text)
      .disposed(by: bag)

    AmountData.shared.boughtCoins
      .filter{ !$0.isEmpty }
      .map{
        self.isCheckProfit($0[coinIndex])
      }
      .subscribe(onNext: {
        switch $0 {
        case .equal:
          self.evaluatedPriceLabel.textColor = .black
        case .profit:
          self.evaluatedPriceLabel.textColor = .systemRed
        case .loss:
          self.evaluatedPriceLabel.textColor = .systemBlue
        }
      })
      .disposed(by: bag)
  }

  private func isCheckProfit(_ coinData: Coin) -> checkProfit {
    var coin = coinData
    if coin.totalBoughtPrice > Double(coin.holdingCount) * (coin.prices?.currentPrice ?? 0) {
      return .loss
    } else if coin.totalBoughtPrice < Double(coin.holdingCount) * (coin.prices?.currentPrice ?? 0){
      return .profit
    } else {
      return .equal
    }
  }


  // MARK: Layout

  private func layout() {

    self.contentView.addSubview(self.nameLabel)
    self.contentView.addSubview(self.holdingCountLabel)
    self.contentView.addSubview(self.totalBoughtPriceLabel)
    self.contentView.addSubview(self.evaluatedPriceLabel)

    self.nameLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(-15)
      $0.leading.equalToSuperview().inset(10)
    }
    self.holdingCountLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(15)
      $0.leading.equalToSuperview().inset(10)
    }
    self.totalBoughtPriceLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(-15)
      $0.trailing.equalToSuperview().inset(10)
    }
    self.evaluatedPriceLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(15)
      $0.trailing.equalToSuperview().inset(10)
    }
  }
}
