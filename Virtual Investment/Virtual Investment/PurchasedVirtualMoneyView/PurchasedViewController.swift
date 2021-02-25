//
//  PurchasedViewController.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import UIKit
import SnapKit

class PurchasedViewController: UIViewController {

  // MARK: Properties

  private let amountData = AmountData.shared


  // MARK: UI

  private let depositLabelTitle: UILabel = {
    let label = UILabel()
    label.text = "총 예수금"
    label.font = .boldSystemFont(ofSize: 20)
    label.sizeToFit()
    return label
  }()
  private lazy var depositLabel: UILabel = {
    let label = UILabel()
    label.text = "\(self.amountData.deposit)"
    label.font = .boldSystemFont(ofSize: 20)
    return label
  }()
  private let evaluatedLabelTitle: UILabel = {
    let label = UILabel()
    label.text = "평가 금액"
    label.font = .boldSystemFont(ofSize: 20)
    label.sizeToFit()
    return label
  }()
  private lazy var evaluatedLabel: UILabel = {
    let label = UILabel()
    label.text = "\(self.amountData.evaluatedPrice)"
    label.textAlignment = .right
    label.font = .boldSystemFont(ofSize: 25)
    return label
  }()
  private let invesetmentLabelTitle: UILabel = {
    let label = UILabel()
    label.text = "투자 금액"
    label.font = .boldSystemFont(ofSize: 20)
    label.sizeToFit()
    return label
  }()
  private lazy var investmentLabel: UILabel = {
    let label = UILabel()
    label.text = "\(self.amountData.investmentAccount)"
    label.textAlignment = .right
    label.font = .boldSystemFont(ofSize: 25)
    return label
  }()
  private let depositContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray6
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.white.cgColor
    return view
  }()
  private let evaluatedContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray6
    return view
  }()
  private let investmentContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray6
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.white.cgColor
    return view
  }()
  private let allContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemBackground
    return view
  }()


  // MARK: View LifeCycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configure()
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.layout()
  }

  private func viewConfigure() {
    self.view.backgroundColor = .systemBackground
    self.title = "투자 내역"
  }


  // MARK: Layout

  private func layout() {
    self.depositContainerView.addSubview(self.depositLabelTitle)
    self.depositContainerView.addSubview(self.depositLabel)
    self.evaluatedContainerView.addSubview(self.evaluatedLabelTitle)
    self.evaluatedContainerView.addSubview(self.evaluatedLabel)
    self.investmentContainerView.addSubview(self.invesetmentLabelTitle)
    self.investmentContainerView.addSubview(self.investmentLabel)
    self.allContainerView.addSubview(self.depositContainerView)
    self.allContainerView.addSubview(self.evaluatedContainerView)
    self.allContainerView.addSubview(self.investmentContainerView)
    self.view.addSubview(self.allContainerView)

    self.allContainerView.snp.makeConstraints {
      $0.width.equalToSuperview()
      $0.leading.equalToSuperview()
      $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
      $0.height.equalToSuperview().multipliedBy(0.2)
    }
    self.investmentContainerView.snp.makeConstraints {
      $0.width.equalToSuperview().multipliedBy(0.5)
      $0.height.equalToSuperview().multipliedBy(0.6)
      $0.leading.equalToSuperview()
      $0.top.equalToSuperview()
    }
    self.evaluatedContainerView.snp.makeConstraints {
      $0.width.equalToSuperview().multipliedBy(0.5)
      $0.height.equalTo(self.investmentContainerView.snp.height)
      $0.trailing.equalToSuperview()
      $0.top.equalToSuperview()
    }
    self.depositContainerView.snp.makeConstraints {
      $0.width.equalToSuperview()
      $0.height.equalToSuperview().multipliedBy(0.4)
      $0.leading.equalToSuperview()
      $0.top.equalTo(self.investmentContainerView.snp.bottom)
    }
    self.invesetmentLabelTitle.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview().offset(-25)
    }
    self.evaluatedLabelTitle.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview().offset(-25)
    }
    self.depositLabelTitle.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview()
    }
    self.evaluatedLabel.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview().offset(20)
    }
    self.investmentLabel.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview().offset(20)
    }
    self.depositLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.trailing.equalToSuperview().inset(10)
    }
  }
}
