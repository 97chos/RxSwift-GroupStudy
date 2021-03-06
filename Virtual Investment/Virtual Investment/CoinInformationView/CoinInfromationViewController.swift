//
//  CoinInfromationViewController.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/25.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class CoinInformationViewController: UIViewController {

  // MARK: Properties

  var viewModel: CoinInformationViewModel
  var bag = DisposeBag()


  // MARK: UI

  private lazy var coinNameLabel: UILabel = {
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 25)
    label.sizeToFit()
    return label
  }()
  private lazy var coinCodeLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 17)
    label.sizeToFit()
    return label
  }()
  private let currentPriceNameLabel: UILabel = {
    let label = UILabel()
    label.text = "현재가"
    label.font = .boldSystemFont(ofSize: 22)
    label.sizeToFit()
    return label
  }()
  private let currentPriceLabel: UILabel = {
    let label = UILabel()
    label.text = "0"
    label.font = .boldSystemFont(ofSize: 22)
    return label
  }()
  private let lowPriceNameLabel: UILabel = {
    let label = UILabel()
    label.text = "금일 저가"
    label.font = .boldSystemFont(ofSize: 18)
    label.sizeToFit()
    return label
  }()
  private let lowPriceLabel: UILabel = {
    let label = UILabel()
    label.text = "0"
    label.font = .boldSystemFont(ofSize: 20)
    return label
  }()
  private let highPriceNameLabel: UILabel = {
    let label = UILabel()
    label.text = "금일 고가"
    label.font = .boldSystemFont(ofSize: 18)
    label.sizeToFit()
    return label
  }()
  private let highPriceLabel: UILabel = {
    let label = UILabel()
    label.text = "0"
    label.font = .boldSystemFont(ofSize: 20)
    return label
  }()
  private let countLabel: UILabel = {
    let label = UILabel()
    label.text = "수량"
    label.font = .boldSystemFont(ofSize: 18)
    return label
  }()
  private let holdingCountLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 13)
    label.textColor = .systemGray2
    return label
  }()
  private let inputCount: UITextField = {
    let textField = UITextField()
    textField.keyboardType = .numberPad
    textField.borderStyle = .roundedRect
    textField.textAlignment = .right
    return textField
  }()
  private let sellButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("매도", for: .normal)
    button.setTitleColor(.systemRed, for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 20)
    button.tag = 0
    return button
  }()
  private let buyButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("매수", for: .normal)
    button.setTitleColor(.systemBlue, for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 20)
    button.tag = 1
    return button
  }()


  // MARK: Initiallizing

  init(viewModel: CoinInformationViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: View LifeCycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configure()
    self.bindLabel()
  }


  // MARK: Actions

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }

  private func buyButtonAction() {
    viewModel.checkInputtedCount(self.buyButton.tag, text: self.inputCount.text)
      .subscribe(onNext: { [weak self] count in
        self?.viewModel.buy(count: count) {
          self?.alert(title: "매수 체결이 완료되었습니다.", message: nil, completion: nil)
        }
      },onError: { [weak self] error in
        let errorType = error as? inputCountError
        self?.alert(title: errorType?.description , message: nil, completion: nil)
      })
      .disposed(by: bag)
  }

  private func sellButtonAction() {
    viewModel.checkInputtedCount(self.sellButton.tag, text: self.inputCount.text)
      .subscribe(onNext: { [weak self] count in
        self?.viewModel.sell(count: count) {
          self?.alert(title: "매도 체결이 완료되었습니다.", message: nil, completion: nil)
        }
      },onError: { [weak self] error in
        let errorType = error as? inputCountError
        self?.alert(title: errorType?.description, message: nil, completion: nil)
      })
      .disposed(by: bag)
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.layout()
    self.bindButton()
  }

  private func viewConfigure() {
    self.view.backgroundColor = .systemBackground
    self.viewModel.bindHoldingCount()
    self.viewModel.isContainCoinInBoughtList()
    self.viewModel.setBoughtCoins()
  }

  private func bindLabel() {
    viewModel.coin
      .map{ $0.koreanName }
      .do(onNext: { [weak self] in self?.title = $0})
      .bind(to: coinNameLabel.rx.text)
      .disposed(by: bag)

    viewModel.coin
      .map{ $0.code }
      .bind(to: self.coinCodeLabel.rx.text)
      .disposed(by: bag)

    viewModel.coin
      .map{ $0.prices?.lowPrice.currenyKRW() }
      .bind(to: self.lowPriceLabel.rx.text)
      .disposed(by: bag)

    viewModel.coin
      .map{ $0.prices?.highPrice.currenyKRW() }
      .bind(to: self.highPriceLabel.rx.text)
      .disposed(by: bag)

    viewModel.coin
      .map{ $0.prices?.currentPrice.currenyKRW() }
      .bind(to: self.currentPriceLabel.rx.text)
      .disposed(by: bag)

    viewModel.coin
      .map{ return "보유 수량 : \($0.holdingCount)" }
      .bind(to: self.holdingCountLabel.rx.text)
      .disposed(by: bag)
  }

  private func bindButton() {
    self.buyButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.buyButtonAction()
      })
      .disposed(by: bag)

    self.sellButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.sellButtonAction()
      })
      .disposed(by: bag)
  }


  // MARK: Layout

  private func layout() {
    self.view.addSubview(self.coinNameLabel)
    self.view.addSubview(self.coinCodeLabel)
    self.view.addSubview(self.currentPriceNameLabel)
    self.view.addSubview(self.currentPriceLabel)
    self.view.addSubview(self.lowPriceNameLabel)
    self.view.addSubview(self.lowPriceLabel)
    self.view.addSubview(self.highPriceNameLabel)
    self.view.addSubview(self.highPriceLabel)
    self.view.addSubview(self.countLabel)
    self.view.addSubview(self.inputCount)
    self.view.addSubview(self.holdingCountLabel)
    self.view.addSubview(self.buyButton)
    self.view.addSubview(self.sellButton)

    self.coinNameLabel.snp.makeConstraints {
      $0.top.equalTo(self.view.layoutMarginsGuide.snp.top).inset(50)
      $0.leading.equalToSuperview().inset(20)
    }
    self.coinCodeLabel.snp.makeConstraints {
      $0.top.equalTo(self.coinNameLabel.snp.bottom).offset(10)
      $0.leading.equalTo(self.coinNameLabel)
    }
    self.highPriceNameLabel.snp.makeConstraints {
      $0.top.equalTo(self.coinCodeLabel).offset(70)
      $0.leading.equalTo(self.coinNameLabel)
    }
    self.highPriceLabel.snp.makeConstraints {
      $0.centerY.equalTo(self.highPriceNameLabel)
      $0.trailing.equalToSuperview().inset(20)
    }
    self.lowPriceNameLabel.snp.makeConstraints {
      $0.top.equalTo(self.highPriceNameLabel).offset(25)
      $0.leading.equalTo(self.coinNameLabel)
    }
    self.lowPriceLabel.snp.makeConstraints {
      $0.centerY.equalTo(self.lowPriceNameLabel)
      $0.trailing.equalToSuperview().inset(20)
    }
    self.currentPriceNameLabel.snp.makeConstraints {
      $0.top.equalTo(self.lowPriceNameLabel).offset(70)
      $0.leading.equalTo(self.coinNameLabel)
    }
    self.currentPriceLabel.snp.makeConstraints {
      $0.centerY.equalTo(self.currentPriceNameLabel)
      $0.trailing.equalToSuperview().inset(20)
    }
    self.countLabel.snp.makeConstraints {
      $0.top.equalTo(self.currentPriceLabel).offset(90)
      $0.leading.equalToSuperview().inset(20)
    }
    self.inputCount.snp.makeConstraints {
      $0.centerY.equalTo(self.countLabel)
      $0.width.equalToSuperview().multipliedBy(0.3)
      $0.trailing.equalToSuperview().inset(20)
    }
    self.holdingCountLabel.snp.makeConstraints {
      $0.top.equalTo(self.inputCount.snp.bottom).offset(10)
      $0.trailing.equalTo(self.inputCount)
    }
    self.buyButton.snp.makeConstraints {
      $0.top.equalTo(self.inputCount).offset(100)
      $0.centerX.equalToSuperview().offset(50)
    }
    self.sellButton.snp.makeConstraints {
      $0.top.equalTo(self.inputCount).offset(100)
      $0.centerX.equalToSuperview().offset(-50)
    }
  }
}
