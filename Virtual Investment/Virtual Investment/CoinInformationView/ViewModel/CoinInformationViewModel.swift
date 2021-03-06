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
  var coin: BehaviorRelay<CoinInfo> = BehaviorRelay<CoinInfo>(value: CoinInfo(koreanName: "", englishName: "", code: "", totalBoughtPrice: 0, holdingCount: 0, prices: nil))
  var holdingCount: Int?
  let bag = DisposeBag()


  // MARK: Initializing

  init(coin: CoinInfo) {
    self.coin.accept(coin)
  }


  // MARK: Functions

  func bindHoldingCount() {
    self.coin
      .map{ $0.holdingCount }
      .subscribe(onNext: { [weak self] in
                  self?.holdingCount = $0 })
      .disposed(by: bag)
  }
  

  // MARK: Logic

  func checkInputtedCount(_ senderTag: Int, text: String?) -> Observable<Int> {
    return Observable.create({ [weak self] observer in
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
        guard self?.holdingCount ?? 0 >= count else {
          observer.onError(inputCountError.deficientHoldingCount)
          return Disposables.create()
        }
      } else if senderTag == 1 {
        let deposit = AD.deposit.value
        guard deposit >= Double(count) * (self?.coin.value.prices?.currentPrice ?? 0) else {
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
    Observable.combineLatest(AD.boughtCoins, self.coin, resultSelector: { [weak self]
      list, coin -> ContainCoinResult in
      if list.contains(coin) {
        guard let index = list.firstIndex(of: coin) else {
          return ContainCoinResult(false, nil, coin)
        }
        self?.boughtCoinsIndex = index
        return ContainCoinResult(true, list[index], coin)
      } else {
        self?.boughtCoinsIndex = nil
        return ContainCoinResult(false, nil, coin)
      }
    })
    .distinctUntilChanged()
    .observe(on: MainScheduler.asyncInstance)
    .subscribe(onNext: { [weak self] result in
      if result.isResult {
        guard let indexCoin = result.indexCoin else { return }
        var coin = result.currentCoin
        coin.holdingCount = indexCoin.holdingCount
        coin.totalBoughtPrice = indexCoin.totalBoughtPrice
        self?.coin.accept(coin)
      } else {
        var coin = result.currentCoin
        coin.holdingCount = 0
        coin.totalBoughtPrice = 0
        self?.coin.accept(coin)
      }
    })
    .disposed(by: bag)
  }

  func setBoughtCoins() {
    AD.boughtCoins
      .map{ coins -> Data? in
        let encodingData = try? PropertyListEncoder().encode(coins)
        return encodingData
      }
      .filter{ $0 != nil }
      .catch{ _ in Observable.empty() }
      .subscribe(onNext: {
        plist.setValue($0, forKey: UserDefaultsKey.boughtCoinList)
      })
      .disposed(by: bag)
  }

  func buy(count: Int, completion: @escaping () -> Void) {
    var currentDeposit = AD.deposit.value
    var list = AD.boughtCoins.value
    var currentCoin = self.coin.value

    if self.boughtCoinsIndex == nil {                                         // 코인을 현재 보유하고 있지 않은 경우 (첫구매)
      let totalPrice: Double = (currentCoin.prices?.currentPrice ?? 0) * Double(count)

      currentDeposit -= totalPrice
      AD.deposit.accept(currentDeposit)

      currentCoin.holdingCount = count
      currentCoin.totalBoughtPrice = totalPrice

      list.append(currentCoin)
      self.boughtCoinsIndex = list.firstIndex(of: currentCoin)

      AD.boughtCoins.accept(list)
      self.coin.accept(currentCoin)
    } else {                                                                   // 코인을 현재 보유하고 있는 경우 (재구매)
      let totalPrice: Double = (currentCoin.prices?.currentPrice ?? 0) * Double(count)

      guard let index = self.boughtCoinsIndex else { return }

      currentDeposit -= totalPrice
      AD.deposit.accept(currentDeposit)

      list[index].holdingCount += count
      list[index].totalBoughtPrice += totalPrice
      self.coin.accept(list[index])
      AD.boughtCoins.accept(list)
    }
    completion()
  }

  func sell(count: Int, completion: () -> Void) {
    var deposit = AD.deposit.value
    let currentCoin = self.coin.value
    var boughtList: [CoinInfo] = AD.boughtCoins.value
    guard let coinIndex = self.boughtCoinsIndex else { return }
    let totalSellPrice: Double = (currentCoin.prices?.currentPrice ?? 0) * Double(count)
    var coinAtIndex = boughtList[coinIndex]

    deposit += totalSellPrice

    coinAtIndex.totalBoughtPrice -= max(boughtList[coinIndex].totalBoughtPrice - totalSellPrice, 0)
    coinAtIndex.holdingCount -= count

    self.coin.accept(coinAtIndex)

    switch coinAtIndex.holdingCount == 0 {
    case true:
      boughtList.remove(at: coinIndex)
      AD.deposit.accept(deposit)
      AD.boughtCoins.accept(boughtList)
    case false:
      boughtList[coinIndex].holdingCount = coinAtIndex.holdingCount
      boughtList[coinIndex].totalBoughtPrice = coinAtIndex.totalBoughtPrice
      AD.boughtCoins.accept(boughtList)
      AD.deposit.accept(deposit)
    }
    completion()
  }

  func buyAction(count: Int, completion: @escaping () -> Void) {
    if self.boughtCoinsIndex == nil {                                         // 코인을 현재 보유하고 있지 않은 경우 (첫구매)
      var totalPrice: Double = 0

      self.coin
        .map{ $0.prices?.currentPrice ?? 0 }
        .subscribe(onNext: { price in
          totalPrice = price * Double(count)
        })
        .disposed(by: bag)

      AD.deposit
        .take(1)
        .map{ price -> Double in
          var currenTotalPrice = price
          currenTotalPrice -= totalPrice
          return currenTotalPrice
        }
        .subscribe(onNext: {
          AD.deposit.accept($0)
        })
        .disposed(by: bag)

      Observable.combineLatest(AD.boughtCoins, self.coin)
        .take(1)
        .map{ boughtList, currentCoin -> ([CoinInfo], CoinInfo) in
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
          AD.boughtCoins.accept($0)
          self.boughtCoinsIndex = $0.firstIndex(of: $1)
        })
        .disposed(by: bag)
    } else {                                                                  // 코인을 현재 보유하고 있는 경우 (재구매)
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

      AD.deposit
        .map{
          var currentTotalPrice = $0
          currentTotalPrice -= totalPrice
          return currentTotalPrice
        }
        .bind(to: AD.deposit)
        .disposed(by: DisposeBag())

      AD.boughtCoins
        .take(1)
        .map{
          var coinList = $0
          coinList[index].holdingCount += count
          coinList[index].totalBoughtPrice += totalPrice
          return coinList
        }
        .do(onNext: { self.coin.accept($0[index]) })
        .bind(to: AD.boughtCoins)
        .disposed(by: bag)
    }
    completion()
  }

  func sellAction(count: Int, completion: () -> Void) {
    var boughtList: [CoinInfo] = []
    var indexCoin: CoinInfo?
    var coinIndex: Int?
    var remainingCount: Int = 0
    var totalRemainingPrice: Double = 0
    var totalCellPrice: Double = 0

    AD.boughtCoins
      .take(1)
      .subscribe(onNext: {
        boughtList = $0
        guard let index = self.boughtCoinsIndex else {
          return
        }
        coinIndex = index
        indexCoin = boughtList[index]
        remainingCount = (indexCoin?.holdingCount ?? 0) - count
      })
      .disposed(by: bag)

    self.coin
      .take(1)
      .map{ $0.prices?.currentPrice ?? 0 }
      .do(onNext: { totalCellPrice = $0 * Double(count) })
      .subscribe(onNext: { price in
        totalRemainingPrice = price * Double(remainingCount)
      })
      .disposed(by: bag)

    AD.deposit
      .map{ deposit -> Double in
        var deposit = deposit
        deposit += totalCellPrice
        return deposit
      }
      .take(1)
      .bind(to: AD.deposit)
      .disposed(by: bag)

    AD.boughtCoins
      .take(1)
      .map{ list -> [CoinInfo] in
        var coinList = list
        guard let index = coinIndex else { return [] }
        coinList[index].totalBoughtPrice -= max(coinList[index].totalBoughtPrice - totalRemainingPrice, 0)
        coinList[index].holdingCount -= count
        return coinList
      }
      .observe(on: MainScheduler.asyncInstance)
      .do{
        guard let index = coinIndex else { return }
        self.coin.accept($0[index])
      }
      .map{
        var coinList = $0
        guard let index = coinIndex else { return [] }
        if coinList[index].holdingCount == 0 {
          coinList.remove(at: index)
        }
        return coinList
      }
      .subscribe(onNext: {
        AD.boughtCoins.accept($0)
      })
      .disposed(by: bag)

    completion()
  }
}
