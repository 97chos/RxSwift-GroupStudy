//
//  CoinInformationViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/06.
//

import Foundation
import RxSwift
import RxCocoa


struct ContainCoinResult {
  var isResult: Bool
  var coin: Coin?
  init (_ boolean: Bool, _ coin: Coin?) {
    self.isResult = boolean
    self.coin = coin
  }
}

extension ContainCoinResult: Equatable {
  static func == (lhs: ContainCoinResult, rhs: ContainCoinResult) -> Bool {
    return lhs.isResult == rhs.isResult
  }
}

class CoinInformationViewModel {

  // MARK: Properties

  var boughtCoinsIndex: Array<Coin>.Index?
  var coin: BehaviorRelay<Coin> = BehaviorRelay<Coin>(value: Coin(koreanName: "코인 이름", englishName: "Coin Name", code: "Coin-code"))
  var isContaining: BehaviorSubject<Bool> = BehaviorSubject<Bool>(value: false)
  let amountData = AmountData.shared
  var holdingCount: Int?
  let bag = DisposeBag()

  init(coin: Coin) {
    self.coin.accept(coin)
  }


  func bindHoldingCount() {
    self.coin
      .map{ var coin = $0
        return coin.holdingCount
      }
      .subscribe(onNext: { self.holdingCount = $0 })
      .disposed(by: bag)
  }

  // MARK: Logic

  func checkInputtedCount(_ senderTag: Int, text: String?, completion: @escaping ((Result<(Int),Error>) -> Void)) {
    guard let inputtedText = text, !inputtedText.isEmpty else {
      completion(.failure(inputCountError.isEmptyField))
      return
    }
    guard let count: Int = Int(inputtedText) else {
      completion(.failure(inputCountError.isNotNumber))
      return
    }
    guard count > 0 else {
      completion(.failure(inputCountError.inputtedZero))
      return
    }
    if senderTag == 0 {
      guard self.holdingCount ?? 0 >= count else {
        completion(.failure(inputCountError.deficientHoldingCount))
        return
      }
    } else if senderTag == 1 {
      guard let deposit = try? self.amountData.deposit.value(), deposit >= Double(count) * (coin.value.prices?.currentPrice ?? 0) else {
        completion(.failure(inputCountError.deficientDeposit))
        return
      }
    }
    completion(.success(count))
  }

  func isContainCoinInBoughtList() {
    Observable.combineLatest(amountData.boughtCoins, self.coin, resultSelector: {list, coin -> ContainCoinResult in
      if list.contains(coin) {
        guard let index = list.firstIndex(of: coin) else {
          return ContainCoinResult(false, nil)
        }
        self.boughtCoinsIndex = index
        return ContainCoinResult(true,list[index])
      } else {
        return ContainCoinResult(false,nil)
      }
    })
    .distinctUntilChanged()
    .subscribe(onNext: { result in
      if result.isResult {
        guard var listIndexCoin = result.coin else {
          return
        }
        let coin = self.coin.value
        self.coin.accept(Coin(koreanName: coin.koreanName, englishName: coin.englishName, code: coin.code, prices: coin.prices, holdingCount: listIndexCoin.holdingCount, totalBoughtPrice: listIndexCoin.totalBoughtPrice))
      }
    })
    .disposed(by: bag)
  }

  func buyAction(count: Int, completion: () -> Void) {
    if self.boughtCoinsIndex == nil {
      var totalPrice: Double = 0

      _ = self.coin
        .take(1)
        .map{ $0.prices?.currentPrice ?? 0 }
        .subscribe(onNext: { price in
          totalPrice = price * Double(count)
        })

      self.amountData.deposit
        .map{ price -> Double in
          var currenTotalPrice = price
          currenTotalPrice -= totalPrice
          return currenTotalPrice
        }
        .take(1)
        .subscribe(onNext: {
          self.amountData.deposit.onNext($0)
        })
        .disposed(by: bag)

      self.coin
        .take(1)
        .subscribe(onNext: { currentCoin in
          self.coin.accept(Coin(koreanName: currentCoin.koreanName, englishName: currentCoin.englishName, code: currentCoin.code, prices: currentCoin.prices, holdingCount: count, totalBoughtPrice: totalPrice))
          self.amountData.boughtCoins.accept(self.amountData.boughtCoins.value + [self.coin.value])
          self.boughtCoinsIndex = self.amountData.boughtCoins.value.firstIndex(of: currentCoin)
        })
        .disposed(by: bag)
    } else {
      var totalPrice: Double = 0
      guard let index = self.boughtCoinsIndex else {
        return
      }

      self.coin
        .map{ ($0.prices?.currentPrice ?? 0) * Double(count) }
        .take(1)
        .subscribe(onNext: {
          totalPrice = $0
        })
        .disposed(by: bag)

      _ = self.amountData.deposit
        .map{
          var currentTotalPrice = $0
          currentTotalPrice -= totalPrice
          return currentTotalPrice
        }
        .take(1)
        .subscribe(onNext: {
          self.amountData.deposit.onNext($0)
        })

      _ = self.amountData.boughtCoins
        .map{
          var coinList = $0
          coinList[index].holdingCount += count
          coinList[index].totalBoughtPrice += totalPrice
          return coinList
        }
        .take(1)
        .subscribe(onNext: {
          self.amountData.boughtCoins.accept($0)
        })

      self.coin.accept(self.amountData.boughtCoins.value[index])
    }
    completion()
  }


  func changeAmountDataBySellAction(count: Int, index: Array<Coin>.Index, completion: () -> Void) {
    var boughtList = self.amountData.boughtCoins.value
    var indexCoin = boughtList[index]
    let remainingCount = indexCoin.holdingCount - count
    var totalRemainingPrice: Double = 0
    var totalCellPrice: Double = 0

    _ = self.coin
      .take(1)
      .map{ $0.prices?.currentPrice ?? 0 }
      .subscribe(onNext: { price in
        totalRemainingPrice = price * Double(remainingCount)
      })

    _ = self.coin
      .take(1)
      .map{ $0.prices?.currentPrice ?? 0 }
      .subscribe(onNext: { price in
        totalCellPrice = price * Double(count)
      })

    _ = self.amountData.boughtCoins
      .take(1)
      .map{
        var coinList = $0
        coinList[index].totalBoughtPrice -= max(coinList[index].totalBoughtPrice - totalRemainingPrice, 0)
        coinList[index].holdingCount -= count
        return coinList
      }
      .subscribe(onNext: {
        self.amountData.boughtCoins.accept($0)
      })

    _ = self.amountData.deposit
      .map{
        var deposit = $0
        deposit += totalCellPrice
        return deposit
      }
      .take(1)
      .subscribe(onNext: {
        self.amountData.deposit.onNext($0)
      })

    indexCoin.holdingCount = remainingCount
    self.holdingCount = remainingCount

    if holdingCount == 0 {
      boughtList.remove(at: index)
      self.amountData.boughtCoins.accept(boughtList)
    }
    completion()
  }
  
}
