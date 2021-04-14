//
//  PurchasedViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/04.
//

import Foundation
import RxSwift
import RxCocoa
import Starscream


class PurchasedViewModel {

  // MARK: Modules

  private enum Constants {
    static let webocketURL = URL(string: "wss://api.upbit.com/websocket/v1")!
  }

  struct Input: InputProtocol {
    let didInitialized = PublishSubject<Void>()
    let connectWebSocket = PublishSubject<Void>()
    let disConnectWebSocket = PublishSubject<Void>()
  }

  struct Output {
    let coinCellViewModels: Observable<[InvestCoinCellViewModel]>
  }


  // MARK: Properties

  let input = Input()
  private(set) lazy var output = Output(coinCellViewModels: self.coinCellViewModels.asObservable())

  private let APIService: CoinServiceProtocol
  private let bag = DisposeBag()

  private let coinCellViewModels = BehaviorSubject<[InvestCoinCellViewModel]>(value: [])
  private let coinInfoList = BehaviorRelay<[CoinInfo]>(value: [])
  private let coinList = BehaviorRelay<[Coin]>(value: [])
  private var tickerObservables: [String: BehaviorRelay<Ticker?>] = [:]

  private lazy var rxWebSocket = RxWebSocket(input: self.input)


  // MARK: Initializing

  init(APIProtocol: CoinServiceProtocol) {
    self.APIService = APIProtocol
    self.bindOutput()
  }


  // MARK: Binding

  private func bindOutput() {
    self.bindCoinCellViewModels()
    self.bindTickers()
    self.rxWebSocket.bindWebSocketLifeCycle(coinList: self.coinList, bag: self.bag)
  }

  private func bindCoinCellViewModels() {
    let coinList = self.input.didInitialized
      .flatMapLatest{ AD.boughtCoins }
      .catch{ _ in Observable.empty() }
      .share()

    coinList.bind(to: self.coinInfoList)
      .disposed(by: self.bag)

    coinList
      .map{ coins in
        coins.map{ coin in
          Coin(koreanName: coin.koreanName, englishName: coin.englishName, code: coin.code)
        }
      }
      .bind(to: self.coinList)
      .disposed(by: self.bag)

    coinList
      .map{ [weak self] coins in
        coins.map { coin in
          InvestCoinCellViewModel(coin: coin, tickerObservable: self?.tickerObservable(code: coin.code).asObservable() ?? .empty())
        }
      }
      .bind(to: self.coinCellViewModels)
      .disposed(by: bag)
  }

  private func bindTickers() {
    self.coinList.asObservable().filter{ !$0.isEmpty }
      .flatMapLatest{ [weak self] coins in
        self?.APIService.tickerList(coins: coins)
          .asObservable()
          .catch { _ in Observable.empty() } ?? .empty()
      }
      .subscribe(onNext: { [weak self] tickers in
        tickers.forEach{ ticker in
          self?.tickerObservable(code: ticker.code).accept(ticker)
        }
      })
      .disposed(by: self.bag)

    self.rxWebSocket.webSocketDidRecieve(bag: self.bag) { ticker in
      self.tickerObservable(code: ticker.code).accept(ticker)
    }
  }

  private func tickerObservable(code: String) -> BehaviorRelay<Ticker?> {
    if let tickerObervable = self.tickerObservables[code] {
      return tickerObervable
    }
    let tickerObservable = BehaviorRelay<Ticker?>(value: nil)
    self.tickerObservables[code] = tickerObservable
    return tickerObservable
  }
  

  private func bindCoinViewModels() {}

  // MARK: Functions

  func getCurrentPrice() -> Completable {
    return Completable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      var coinList: [Coin] = []
      AD.boughtCoins
        .map{ $0.map{ Coin(koreanName: $0.koreanName, englishName: $0.englishName, code: $0.code) } }
        .subscribe(onNext: {
          coinList = $0
        })
        .disposed(by: self.bag)

      if !coinList.isEmpty {
        Observable.combineLatest(self.APIService.tickerList(coins: coinList).asObservable(), AD.boughtCoins)
          .take(1)
          .map{ tickerData, immutableList -> [CoinInfo] in
            var coinList = immutableList
            tickerData.enumerated().forEach{ index, prices in
              coinList[index].prices?.currentPrice = prices.currentPrice
            }
            return coinList
          }
          .observe(on: MainScheduler.asyncInstance)
          .subscribe(onNext: {
            AD.boughtCoins.accept($0)
            observer(.completed)
          }, onError: {
            observer(.error($0))
          })
          .disposed(by: self.bag)
      }
      return Disposables.create()
    }
  }

  func checkProfit(_ investedPrice: Double, _ evaluatedPrice: Double) -> checkProfit {
    if investedPrice > evaluatedPrice {
      return .profit
    } else if investedPrice < evaluatedPrice {
      return .loss
    } else {
      return .equal
    }
  }
}
