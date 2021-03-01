//
//  CoinInfromationViewController.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/25.
//

import Foundation
import UIKit

class CoinInformationViewController: UIViewController {

  // MARK: Properties

  private var boughtCoinsIndex: Array<Coin>.Index?
  private var coin: Coin
  private let amountData = AmountData.shared
  private var holdingCount: Int?


  // MARK: UI

  private lazy var coinNameLabel: UILabel = {
    let label = UILabel()
    label.text = self.coin.koreanName
    label.font = .boldSystemFont(ofSize: 25)
    label.sizeToFit()
    return label
  }()
  private lazy var coinCodeLabel: UILabel = {
    let label = UILabel()
    label.text = self.coin.code
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
    return button
  }()
  private let buyButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("매수", for: .normal)
    button.setTitleColor(.systemBlue, for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 20)
    return button
  }()



  // MARK: Initializing

  init(coin: Coin) {
    self.coin = coin
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: View LifeCycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configure()
  }

  override func viewWillAppear(_ animated: Bool) {
    self.getIndexAndHoldingCountInBoughtList()
    self.getPrices()
  }


  // MARK: Actions

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }

  @objc private func buyButtonAction() {
    if let count = self.checkInputtedCount(self.buyButton) {
      switch isContainCoinInBoughtList() {
      case true:
        let totalPrice = (self.coin.prices?.currentPrice ?? 0) * Double(count)

        guard let index = self.boughtCoinsIndex else {
          return
        }

        self.amountData.boughtCoins[index].totalBoughtPrice += totalPrice
        self.amountData.deposit -= totalPrice
        self.amountData.boughtCoins[index].holdingCount += count
        self.coin.holdingCount = self.amountData.boughtCoins[index].holdingCount

        self.holdingCountLabel.text = "보유 수량 : \(self.coin.holdingCount)"

        self.alert(title: "매수 체결이 완료되었습니다.", message: nil, completion: nil)

      case false:
        let totalPrice = (self.coin.prices?.currentPrice ?? 0) * Double(count)

        self.coin.totalBoughtPrice = totalPrice
        self.amountData.deposit -= totalPrice
        self.coin.holdingCount = count

        self.amountData.boughtCoins.append(self.coin)

        self.holdingCountLabel.text = "보유 수량 : \(self.coin.holdingCount)"

        self.alert(title: "매수 체결이 완료되었습니다.", message: nil, completion: nil)
      }
    } else {
      return
    }
  }

  @objc private func sellButtonAction() {
    if let count = self.checkInputtedCount(self.sellButton) {

      guard let index = self.boughtCoinsIndex else {
        return
      }

      let remainingCount = self.amountData.boughtCoins[index].holdingCount - count
      let totalRemainingPrice = (self.coin.prices?.currentPrice ?? 0) * Double(remainingCount)
      let totalCellPrice =  (self.coin.prices?.currentPrice ?? 0) * Double(count)

      self.amountData.boughtCoins[index].totalBoughtPrice -= max(self.amountData.boughtCoins[index].totalBoughtPrice - totalRemainingPrice, 0)
      self.amountData.deposit += totalCellPrice
      self.amountData.boughtCoins[index].holdingCount -= count
      self.coin.holdingCount = self.amountData.boughtCoins[index].holdingCount

      if self.amountData.boughtCoins[index].holdingCount == 0 {
        self.amountData.boughtCoins.remove(at: index)
      }
      self.holdingCountLabel.text = "보유 수량 : \(self.coin.holdingCount)"

      self.alert(title: "매도 체결이 완료되었습니다.", message: nil, completion: nil)
    } else {
      return
    }
  }


  private func checkInputtedCount(_ sender: UIButton) -> Int? {
    let optText = self.inputCount.text
    guard let text = optText else {
      self.alert(title: "매매할 수량을 입력해주세요.", message: nil, completion: nil)
      return nil
    }
    guard let count: Int = Int(text) else {
      self.alert(title: "숫자 외 다른 문자는 입력이 불가능합니다.", message: nil, completion: nil)
      return nil
    }
    guard count > 0 else {
      self.alert(title: "1 이상의 숫자만 입력 가능합니다.", message: nil, completion: nil)
      return nil
    }
    if sender == self.buyButton {
      guard self.amountData.deposit >= Double(count) * (coin.prices?.currentPrice ?? 0) else {
        self.alert(title: "보유 중인 예수금이 부족합니다.", message: nil, completion: nil)
        return nil
      }
    } else if sender == self.sellButton {
      guard self.coin.holdingCount >= count else {
        self.alert(title: "보유 중인 수량이 부족합니다.", message: nil, completion: nil)
        return nil
      }
    }
    return count
  }

  private func isContainCoinInBoughtList() -> Bool {
    if self.amountData.boughtCoins.contains(where: {$0.code == self.coin.code}) {
      return true
    } else {
      return false
    }
  }

  private func getIndexAndHoldingCountInBoughtList() {
    if self.isContainCoinInBoughtList() {
      guard let index = self.amountData.boughtCoins.firstIndex(where: { $0.code == self.coin.code }) else {
        return
      }
      self.boughtCoinsIndex = index
      self.coin.holdingCount = self.amountData.boughtCoins[index].holdingCount
    } else {
      self.boughtCoinsIndex = nil
      self.coin.holdingCount = 0
    }
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.layout()
    self.buttonConfigure()
  }

  private func viewConfigure() {
    self.title = self.coin.koreanName
    self.view.backgroundColor = .systemBackground
  }

  private func getPrices() {
    self.currentPriceLabel.text = "\((self.coin.prices?.currentPrice ?? 0).currenyKRW())"
    self.lowPriceLabel.text = "\((self.coin.prices?.lowPrice ?? 0).currenyKRW())"
    self.highPriceLabel.text = "\((self.coin.prices?.highPrice ?? 0).currenyKRW())"
    self.holdingCountLabel.text = "보유 수량 : \(self.coin.holdingCount)"
  }

  private func buttonConfigure() {
    self.buyButton.addTarget(self, action: #selector(self.buyButtonAction), for: .touchUpInside)
    self.sellButton.addTarget(self, action: #selector(self.sellButtonAction), for: .touchUpInside)
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
