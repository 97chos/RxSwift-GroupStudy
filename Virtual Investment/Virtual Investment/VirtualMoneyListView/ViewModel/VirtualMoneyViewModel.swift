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


protocol WebSocektErrorDelegation: class {
  func sendSuccessResult(_ index: Int)
  func sendFailureResult(_ errorType: WebSocketError)
}

class VirtualMoneyViewModel {

  // MARK: Properties

  var coinList: BehaviorRelay = BehaviorRelay<[Coin]>(value: [])
  var codeList: [String] = []
  private let bag = DisposeBag()
  private var request = URLRequest(url: URL(string: "wss://api.upbit.com/websocket/v1")!)
  private var APIService: APIServiceProtocol

  lazy var webSocket = WebSocket(request: self.request, certPinner: FoundationSecurity(allowSelfSigned: true))
  weak var delegate: WebSocektErrorDelegation?


  // MARK: Initializing

  init(APIProtocol: APIServiceProtocol) {
    self.APIService = APIProtocol
  }


  // MARK: Functions

  private func extractCodeList() {
    self.coinList
      .take(1)
      .map{ $0.map{ $0.code }}
      .subscribe(onNext: {
        self.codeList = $0
      })
      .disposed(by: bag)
  }

  func lookUpCoinList() -> Completable {
    var completedCoins: [Coin] = []
    let missingPriceCoins = self.APIService.lookupCoinListRx()
      .flatMap{ Observable.from($0) }

    let tickerData = Observable<ticker>.create({ [weak self] oberver in
      guard let self = self else { return Disposables.create() }
      self.APIService.lookupCoinListRx()
        .subscribe(onNext: {
          self.APIService.loadCoinsTickerDataRx(coins: $0)
            .flatMap({ Observable.from($0) })
            .subscribe(onNext: {
              oberver.onNext($0)
            })
            .disposed(by: self.bag)
        })
        .disposed(by: self.bag)
      return Disposables.create()
    })

    return Completable.create(subscribe: { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      Observable.zip(missingPriceCoins,tickerData) { immutableCoin, ticker -> Coin in
        var coin = immutableCoin
        coin.prices = ticker
        return coin
      }
      .subscribe(onNext: {
        completedCoins.append($0)
        self.coinList.accept(completedCoins)
      },onError: { error in
        observer(.error(error))
      })
      .disposed(by: self.bag)

      return Disposables.create()
    })
  }

  //  func autoScrollLoadCoins() -> Completable {
  //    return Completable.create(subscribe: { [weak self] observe in
  //      guard let self = self else { return Disposables.create() }
  //      self.APIService.lookupCoinListRx()
  //        .flatMap{ Observable.from($0) }
  //        .take(10)
  //        .subscribe(onNext: { missingPriceCoin in
  //          var list: [Coin] = []
  //          self.APIService.loadCoinTickerDataRx(coin: missingPriceCoin)
  //            .subscribe(onNext: {compltableCoin in
  //              list.append(compltableCoin)
  //            },onCompleted: { self.coinList.accept(self.coinList.value + list)})
  //            .disposed(by: self.bag)
  //        })
  //        .disposed(by: self.bag)
  //      return Disposables.create()
  //    })
  //  }
}


// MARK: WebScoket Delegation

extension VirtualMoneyViewModel: WebSocketDelegate {
  func connect() {
    request.timeoutInterval = 100
    webSocket.delegate = self
    webSocket.connect()
  }

  func disconnect() {
    webSocket.disconnect()
  }

  func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch(event) {
    case .connected(_):
      let ticket = TicketField(ticket: "test")
      let format = FormatField(format: "SIMPLE")
      let type = TypeField(type: "ticker", codes: self.coinList.value.map{ $0.code }, isOnlySnapshot: false, isOnlyRealtime: true)

      let encoder = JSONEncoder()

      let parameterStrings = [
        try? encoder.encode(ticket),
        try? encoder.encode(format),
        try? encoder.encode(type)
      ]
      .compactMap{$0}
      .compactMap { String(data: $0, encoding: .utf8) }

      let params = "[" + parameterStrings.joined(separator: ",") + "]"

      guard let data = params.data(using: .utf8) else {
        return
      }
      guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String:AnyObject]] else {
        return
      }
      guard let jParams = try? JSONSerialization.data(withJSONObject: json, options: []) else {
        return
      }
      client.write(string: String(data:jParams, encoding: .utf8) ?? "", completion: nil)

    case .binary(let data):
      do {
        //
        //        let decoder = JSONDecoder()
        //        let tickerData = try decoder.decode(ticker.self, from: data)
        //
        //        self.coinList
        //          .take(1)
        //          .map{ list in
        //            return (list, Dictionary(grouping: list, by: { $0.code }))
        //          }
        //          .map{ list, dic -> ([Coin], Coin?, Int?) in
        //            var coin = dic[tickerData.code]?.first
        //            coin?.prices = tickerData
        //            let index = list.firstIndex(where: {$0.code == coin?.code})
        //            return (list, coin, index)
        //          }
        //          .filter{ list, coin, index in coin != nil && index != nil }
        //          .observe(on: MainScheduler.asyncInstance)
        //          .subscribe(onNext: { immutableList, coin, index in
        //            var list = immutableList
        //            list[index!] = coin!
        //            self.coinList.accept(list)
        //          },onDisposed: { print("diisposed")})
        //          .disposed(by: bag)

        var listValue = self.coinList.value
        let decoder = JSONDecoder()
        let tickerData = try decoder.decode(ticker.self, from: data)
        let codeDic = Dictionary(grouping: listValue, by: { $0.code })

        guard var coin = codeDic[tickerData.code]?.first else { return }
        guard let index = listValue.firstIndex(where: { $0.code == coin.code }) else { return }
        coin.prices = tickerData

        listValue[index] = coin

        self.coinList.accept(listValue)
      } catch {
        self.delegate?.sendFailureResult(WebSocketError.decodingError)
      }

    case .error(_):
      self.delegate?.sendFailureResult(WebSocketError.connectError)

    default:
      break
    }
  }
}
