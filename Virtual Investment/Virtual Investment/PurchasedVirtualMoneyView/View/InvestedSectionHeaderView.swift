//
//  investedSectionHeaderView.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/28.
//

import Foundation
import UIKit

class InvestedSectionHeaderView: UITableViewHeaderFooterView {

  // MARK: UI

  private let coinTitle: UILabel = {
    let label = UILabel()
    label.text = "Coin"
    label.font = .boldSystemFont(ofSize: 13)
    return label
  }()
  private let coinBoughtPriceLabel: UILabel = {
    let label = UILabel()
    label.text = "총 구매 금액"
    label.font = .boldSystemFont(ofSize: 13)
    return label
  }()
  private let coinEvaluatedPriceLabel: UILabel = {
    let label = UILabel()
    label.text = "평가 금액"
    label.font = .boldSystemFont(ofSize: 13)
    return label
  }()


  // MARK: Initializing

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    self.layout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: Layout

  private func layout() {
    self.contentView.addSubview(self.coinTitle)
    self.contentView.addSubview(self.coinBoughtPriceLabel)
    self.contentView.addSubview(self.coinEvaluatedPriceLabel)

    self.coinTitle.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().inset(10)
    }
    self.coinBoughtPriceLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(-10)
      $0.trailing.equalToSuperview().inset(10)
    }
    self.coinEvaluatedPriceLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview().offset(10)
      $0.trailing.equalToSuperview().inset(10)
    }
  }
}
