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
    return Completable.create(subscribe: { observer in
      self.APIService.lookupCoinListRx()
        .subscribe(onNext: { [weak self] list in
          var missingPriceCoins = list
          guard let self = self else { return }
          self.APIService.loadCoinsTickerDataRx(coins: missingPriceCoins)
            .map{ tickerList -> [Coin] in
              let groupingList = Dictionary(grouping: tickerList, by: {$0.code})
              groupingList.enumerated().forEach{ index, dic in
                let ticker = groupingList[missingPriceCoins[index].code]?.first
                missingPriceCoins[index].prices = ticker
              }
              return missingPriceCoins
            }
            .subscribe(onNext: { completeCoins in
              self.coinList
                .distinctUntilChanged()
                .subscribe(onNext: { _ in
                  self.coinList.accept(completeCoins)
                  observer(.completed)
                },onError: { _ in
                  observer(.error(APIError.parseError))
                })
                .disposed(by: self.bag)
            }, onError: { _ in
              observer(.error(APIError.loadCoinTickerError))
            })
            .disposed(by: self.bag)
        }, onError: { _ in
          observer(.error(APIError.loadCoinNameError))
        })
        .disposed(by: self.bag)
      return Disposables.create()
    })
  }
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
