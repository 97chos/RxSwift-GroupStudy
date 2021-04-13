//
//  VirtualMoneyViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/03.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Starscream
import CoreData

protocol WebSocektErrorDelegation: class {
  func sendFailureResult(_ errorType: WebSocketError)
}

class VirtualMoneyViewModel {

  // MARK: Modules

  private enum Constants {
    static let webocketURL = URL(string: "wss://api.upbit.com/websocket/v1")!
  }

  struct Input {
    let didInitialized = PublishSubject<Void>()
    let connectWebSocket = PublishSubject<Void>()
    let disConnectWebSocket = PublishSubject<Void>()
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
  private lazy var webSocket = WebSocket(request: URLRequest(url: Constants.webocketURL), certPinner: FoundationSecurity(allowSelfSigned: true))



  // MARK: Initializing

  init(coinService: CoinServiceProtocol) {
    self.coinService = coinService
    self.bindOutput()
  }


  // MARK: Binding

  private func bindOutput() {
    self.bindCoinCellViewModels()
    self.bindTickers()
    self.bindWebSocket()
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

    self.webSocket.rx.didReceive
      .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .compactMap { event -> Data? in
        guard case let .binary(response) = event else { return nil }
        return response
      }
      .map { try JSONDecoder().decode(Ticker.self, from: $0) }
      .catch { _ in Observable.empty() }
      .subscribe(onNext: { [weak self] ticker in
        self?.tickerObservable(code: ticker.code).accept(ticker)
      })
      .disposed(by: self.bag)
  }

  private func tickerObservable(code: String) -> BehaviorRelay<Ticker?> {
    if let tickerObservable = self.tickerObservables[code] {
      return tickerObservable
    }
    let tickerObservable = BehaviorRelay<Ticker?>(value: nil)
    self.tickerObservables[code] = tickerObservable
    return tickerObservable
  }

  private func bindWebSocket() {
    self.input.connectWebSocket
      .subscribe(onNext: { [weak self] in
        self?.webSocket.connect()
      })
      .disposed(by: self.bag)

    self.input.disConnectWebSocket
      .subscribe(onNext: { [weak self] in
        self?.webSocket.disconnect()
      })
      .disposed(by: self.bag)

    let onConnected = self.webSocket.rx.didReceive
      .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .compactMap { event -> [String: String]? in
        guard case let .connected(response) = event else { return nil }
        return response
      }

    Observable.combineLatest(onConnected, self.coinList.filter { !$0.isEmpty })
      .subscribe(onNext: { [weak self] _, coinList in
        self?.sendRequestTickers(coinList: coinList)
      })
      .disposed(by: self.bag)
  }

  private func sendRequestTickers(coinList: [Coin]) {
    let ticket = TicketField(ticket: "test")
    let format = FormatField(format: "SIMPLE")
    let type = TypeField(type: "ticker", codes: coinList.map(\.code), isOnlySnapshot: false, isOnlyRealtime: true)
    let encoder = JSONEncoder()
    let parameterStrings = [
      try? encoder.encode(ticket),
      try? encoder.encode(format),
      try? encoder.encode(type)
    ]
    .compactMap{$0}
    .compactMap { String(data: $0, encoding: .utf8) }
    let params = "[" + parameterStrings.joined(separator: ",") + "]"
    guard let data = params.data(using: .utf8) else { return }
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String:AnyObject]] else { return }
    guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else { return }
    self.webSocket.write(data: jsonData)
  }

  private func bindReset() {
    self.input.didReseted
      .subscribe(onNext: {
        coreData.clear()
        plist.set(0, forKey: UserDefaultsKey.remainingDeposit)
        plist.set(false, forKey: UserDefaultsKey.isCheckingUser)
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
