//
//  CoinInformationViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/06.
//

import Foundation
import RxSwift
import RxCocoa


class CoinInformationViewModel {

  // MARK: Properties

  var boughtCoinsIndex: Array<Coin>.Index?
  var coin: BehaviorRelay<Coin> = BehaviorRelay<Coin>(value: Coin(koreanName: "코인 이름", englishName: "Coin Name", code: "Coin-code"))
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

  func checkInputtedCount(_ senderTag: Int, text: String?) -> Observable<Int> {
    return Observable.create({ observer in
      guard let inputtedText = text, !inputtedText.isEmpty else {
        observer.onError(inputCountError.isEmptyField)
        return Disposables.create()
      }
      guard let count: Int = Int(inputtedText) else {
        observer.onError(inputCountError.isNotNumber)
        return Disposables.create()
      }
      guard count > 0 else {
        observer.onError(inputCountError.inputtedZero)
        return Disposables.create()
      }
      if senderTag == 0 {
        guard self.holdingCount ?? 0 >= count else {
          observer.onError(inputCountError.deficientHoldingCount)
          return Disposables.create()
        }
      } else if senderTag == 1 {
        guard let deposit = try? self.amountData.deposit.value(), deposit >= Double(count) * (self.coin.value.prices?.currentPrice ?? 0) else {
          observer.onError(inputCountError.deficientDeposit)
          return Disposables.create()
        }
      }
      observer.onNext(count)
      observer.onCompleted()
      return Disposables.create()
    })
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
        self.boughtCoinsIndex = nil
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

  func buyAction(count: Int, completion: @escaping () -> Void) {
    if self.boughtCoinsIndex == nil {
      var totalPrice: Double = 0

      self.coin
        .take(1)
        .map{ $0.prices?.currentPrice ?? 0 }
        .subscribe(onNext: { price in
          totalPrice = price * Double(count)
        })
        .disposed(by: bag)

      self.amountData.deposit
        .take(1)
        .map{ price -> Double in
          var currenTotalPrice = price
          currenTotalPrice -= totalPrice
          return currenTotalPrice
        }
        .subscribe(onNext: {
          self.amountData.deposit.onNext($0)
        })
        .disposed(by: bag)

      Observable.combineLatest(AmountData.shared.boughtCoins, self.coin)
        .take(1)
        .map{ boughtList, currentCoin -> ([Coin], Coin) in
          var list = boughtList
          var coin = currentCoin

          coin.holdingCount = count
          coin.totalBoughtPrice = totalPrice
          list.append(coin)
          return (list, coin)
        }
        .observe(on: MainScheduler.asyncInstance)
        .subscribe(onNext: {
          self.coin.accept($1)
          AmountData.shared.boughtCoins.accept($0)
          self.boughtCoinsIndex = $0.firstIndex(of: $1)
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

      self.amountData.deposit
        .take(1)
        .map{
          var currentTotalPrice = $0
          currentTotalPrice -= totalPrice
          return currentTotalPrice
        }
        .observe(on: MainScheduler.asyncInstance)
        .subscribe(onNext: {
          self.amountData.deposit.onNext($0)
        })
        .disposed(by: bag)

      self.amountData.boughtCoins
        .take(1)
        .map{
          var coinList = $0
          coinList[index].holdingCount += count
          coinList[index].totalBoughtPrice += totalPrice
          return coinList
        }
        .subscribe(onNext: {
          self.amountData.boughtCoins.accept($0)
        })
        .disposed(by: bag)

      self.coin.accept(self.amountData.boughtCoins.value[index])
    }
    completion()
  }


  func sellAction(count: Int, completion: () -> Void) {
    let boughtList = self.amountData.boughtCoins.value
    guard let index = self.boughtCoinsIndex else {
      return
    }
    var indexCoin = boughtList[index]
    let remainingCount = indexCoin.holdingCount - count
    var totalRemainingPrice: Double = 0
    var totalCellPrice: Double = 0

    self.coin
      .take(1)
      .map{ $0.prices?.currentPrice ?? 0 }
      .subscribe(onNext: { price in
        totalRemainingPrice = price * Double(remainingCount)
      })
      .disposed(by: bag)

    self.coin
      .take(1)
      .map{ $0.prices?.currentPrice ?? 0 }
      .subscribe(onNext: { price in
        totalCellPrice = price * Double(count)
      })
      .disposed(by: bag)

    self.amountData.deposit
      .map{
        var deposit = $0
        deposit += totalCellPrice
        return deposit
      }
      .take(1)
      .observe(on: MainScheduler.asyncInstance)
      .subscribe(onNext: {
        self.amountData.deposit.onNext($0)
      })
      .disposed(by: bag)

    self.amountData.boughtCoins
      .take(1)
      .map{ list -> [Coin] in
        var coinList = list
        coinList[index].totalBoughtPrice -= max(coinList[index].totalBoughtPrice - totalRemainingPrice, 0)
        coinList[index].holdingCount -= count
        return coinList
      }
      .observe(on: MainScheduler.asyncInstance)
      .do{
        self.coin.accept($0[index])
      }
      .map{
        var coinList = $0
        if coinList[index].holdingCount == 0 {
          coinList.remove(at: index)
        }
        return coinList
      }
      .subscribe(onNext: {
        self.amountData.boughtCoins.accept($0)
      })
      .disposed(by: bag)

    completion()
  }
}
