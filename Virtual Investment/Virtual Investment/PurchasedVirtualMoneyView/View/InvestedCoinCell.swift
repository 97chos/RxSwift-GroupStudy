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

  var bag = DisposeBag()

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

  func setViewModel(viewModel: InvestCoinCellViewModel) {
    self.bag = DisposeBag()

    self.nameLabel.text = "\(viewModel.coin.koreanName)(\(viewModel.coin.code))"
    self.holdingCountLabel.text = "보유 수량 : \(viewModel.coin.holdingCount)"
    self.totalBoughtPriceLabel.text = "\(viewModel.coin.totalBoughtPrice)"
    self.evaluatedPriceLabel.text = nil

    viewModel.tickerObservable
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] ticker in
        self?.evaluatedPriceLabel.text = Double(ticker?.currentPrice ?? 0 * Double(viewModel.coin.holdingCount)).cutDecimal()
      })
      .disposed(by: self.bag)

    self.setNeedsLayout()
  }

  func set(coinIndex: Int) {
    AD.boughtCoins
      .filter{ $0.count > coinIndex }
      .map{ $0[coinIndex] }
      .map{ "\($0.koreanName) (\($0.englishName))" }
      .bind(to: self.nameLabel.rx.text)
      .disposed(by: bag)

    AD.boughtCoins
      .filter{ $0.count > coinIndex }
      .map{ $0[coinIndex] }
      .map{ return "보유 수량 : \($0.holdingCount)" }
      .bind(to: self.holdingCountLabel.rx.text)
      .disposed(by: bag)

    AD.boughtCoins
      .filter{ $0.count > coinIndex }
      .map{ $0[coinIndex]}
      .map{ $0.totalBoughtPrice.cutDecimal() }
      .bind(to: self.totalBoughtPriceLabel.rx.text)
      .disposed(by: bag)

    AD.boughtCoins
      .filter{ $0.count > coinIndex }
      .map{ $0[coinIndex] }
      .map{ (($0.prices?.currentPrice ?? 0) * Double($0.holdingCount)).cutDecimal() }
      .bind(to: self.evaluatedPriceLabel.rx.text)
      .disposed(by: bag)

    AD.boughtCoins
      .filter{ $0.count > coinIndex }
      .map{
        self.isCheckProfit($0[coinIndex])
      }
      .subscribe(onNext: { [weak self] in
        switch $0 {
        case .equal:
          self?.evaluatedPriceLabel.textColor = .black
        case .profit:
          self?.evaluatedPriceLabel.textColor = .systemRed
        case .loss:
          self?.evaluatedPriceLabel.textColor = .systemBlue
        }
      })
      .disposed(by: bag)
  }

  private func isCheckProfit(_ coin: CoinInfo) -> checkProfit {
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
