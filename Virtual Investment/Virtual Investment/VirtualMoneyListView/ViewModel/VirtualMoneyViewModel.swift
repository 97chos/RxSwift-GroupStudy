//
//  VirtualMoneyViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/03.
//

import Foundation
import RxSwift
import RxCocoa
import Starscream

protocol WebSocektErrorDelegation: class {
  func sendFailureResult(_ errorType: WebSocketError)
}

class VirtualMoneyViewModel {

  // MARK: Modules

  struct Input: InputProtocol {
    let didInitialized = PublishSubject<Void>()
    var connectWebSocket = PublishSubject<Void>()
    var disConnectWebSocket = PublishSubject<Void>()
    let didReseted = PublishSubject<Void>()
    let inputtedSearchText = BehaviorSubject<String?>(value: nil)
  }

  struct Output {
    let coinCellViewModels: Observable<[CoinCellViewModel]>
  }


  // MARK: Properties

  let input = Input()
  private(set) lazy var output = Output(coinCellViewModels: self.coinCellViewModels.asObservable())

  private let coinService: CoinServiceProtocol
  private let bag = DisposeBag()

  private let coinCellViewModels = BehaviorRelay<[CoinCellViewModel]>(value: [])
  private let coinList = BehaviorRelay<[Coin]>(value: [])
  private var tickerObservables: [String: BehaviorRelay<Ticker?>] = [:]

  private lazy var rxWebSocket = RxWebSocket(input: self.input)


  // MARK: Initializing

  init(coinService: CoinServiceProtocol) {
    self.coinService = coinService
    self.bindOutput()
  }


  // MARK: Binding

  private func bindOutput() {
    self.bindCoinCellViewModels()
    self.bindTickers()
    self.rxWebSocket.bindWebSocketLifeCycle(coinList: self.coinList, bag: self.bag)
    self.bindReset()
  }

  private func bindCoinCellViewModels() {
    let coinList = self.input.didInitialized
      .flatMapLatest { [weak self] in
        self?.coinService.coinList() ?? .never()
      }
      .catch { _ in Observable.empty() }
      .share()

    coinList.bind(to: self.coinList)
      .disposed(by: self.bag)

    Observable.combineLatest(self.input.inputtedSearchText, coinList) { text, coinList -> [Coin] in
      if let searchingText = text {
        return coinList.filter{ $0.code.hasPrefix(searchingText) || $0.englishName.hasPrefix(searchingText) || $0.koreanName.hasPrefix(searchingText)}
      } else {
        return coinList
      }
    }
    .map{ [weak self] coins in
      coins.map{ coin in
        CoinCellViewModel(
          coin: coin,
          tickerObservable: self?.tickerObservable(code: coin.code).asObservable() ?? .empty()
        )
      }
    }
    .bind(to: self.coinCellViewModels)
    .disposed(by: bag)
  }

  private func bindTickers() {
    self.coinList.asObservable().filter { !$0.isEmpty }
      .flatMapLatest { [weak self] coins in
        self?.coinService.tickerList(coins: coins)
          .asObservable()
          .catch { _ in Observable.empty() } ?? .empty()
      }
      .subscribe(onNext: { [weak self] tickers in
        tickers.forEach { ticker in
          self?.tickerObservable(code: ticker.code).accept(ticker)
        }
      })
      .disposed(by: self.bag)

    self.rxWebSocket.webSocketDidRecieve(bag: self.bag) { ticker in
      self.tickerObservable(code: ticker.code).accept(ticker)
    }
  }

  private func tickerObservable(code: String) -> BehaviorRelay<Ticker?> {
    if let tickerObservable = self.tickerObservables[code] {
      return tickerObservable
    }
    let tickerObservable = BehaviorRelay<Ticker?>(value: nil)
    self.tickerObservables[code] = tickerObservable
    return tickerObservable
  }

  private func bindReset() {
    self.input.didReseted
      .subscribe(onNext: {
        plist.set(0, forKey: UserDefaultsKey.remainingDeposit)
        plist.set(false, forKey: UserDefaultsKey.isCheckingUser)
        //plist.set([], forKey: UserDefaultsKey.boughtCoinList)
      })
      .disposed(by: bag)

    self.input.didReseted
      .map { _ in
        let empty: [CoinInfo] = []
        return empty
      }
      .bind(to: AD.boughtCoins)
      .disposed(by: bag)
  }
}
