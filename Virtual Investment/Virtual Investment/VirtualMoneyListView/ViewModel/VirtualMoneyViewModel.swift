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
  var bag = DisposeBag()
  var request = URLRequest(url: URL(string: "wss://api.upbit.com/websocket/v1")!)

  lazy var webSocket = WebSocket(request: self.request, certPinner: FoundationSecurity(allowSelfSigned: true))
  weak var delegate: WebSocektErrorDelegation?


  // MARK: Functions

  func lookUpCoinList(completion: @escaping (Result<(),Error>) -> Void) {
    APIService().lookupCoinListRx()
      .subscribe(onNext: { coinList in
        self.coinList.accept(coinList)
        completion(.success(()))
      }, onError: { error in
        completion(.failure(error))
      })
      .disposed(by: bag)
  }

  func loadTickerData(completion: @escaping (Result<(),Error>) -> Void) {
    var codeList: [String] = []
    self.coinList.value.forEach {
      codeList.append($0.code)
    }
    APIService().loadCoinsTickerDataRx(codes: codeList)
      .subscribe(onNext: { [weak self] tickerList in
        var copyCoinList = self?.coinList.value
        tickerList.enumerated().forEach { index, prices in
          copyCoinList?[index].prices = prices
        }
        self?.coinList.accept(copyCoinList ?? [])
        completion(.success(()))
      }, onError: { error in
        completion(.failure(error))
      })
      .disposed(by: bag)
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
        let decoder = JSONDecoder()
        let tickerData = try decoder.decode(ticker.self, from: data)
        let codeDic = Dictionary(grouping: self.coinList.value, by: { $0.code })

        guard var coin = codeDic[tickerData.code]?.first else { return }
        guard let index = self.coinList.value.firstIndex(where: { $0.code == coin.code }) else { return }
        coin.prices = tickerData

        var copyCoinList = self.coinList.value
        copyCoinList[index] = coin
        let indexInteger = coinList.value.index(0, offsetBy: index)

        self.coinList.accept(copyCoinList)
        DispatchQueue.main.async {
          self.delegate?.sendSuccessResult(indexInteger)
        }
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
