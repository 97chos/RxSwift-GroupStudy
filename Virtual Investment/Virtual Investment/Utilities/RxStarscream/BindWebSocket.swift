//
//  BindWebSocket.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/04/14.
//

import Foundation
import Starscream
import RxSwift
import RxCocoa

protocol InputProtocol {
  var connectWebSocket: PublishSubject<Void> { get }
  var disConnectWebSocket: PublishSubject<Void> { get }
}

class RxWebSocket {

  let input: InputProtocol

  init(input: InputProtocol) {
    self.input = input
  }

  private enum Constants {
    static let webocketURL = URL(string: "wss://api.upbit.com/websocket/v1")!
  }

  private lazy var webSocket = WebSocket(request: URLRequest(url: Constants.webocketURL), certPinner: FoundationSecurity(allowSelfSigned: true))


  func webSocketDidRecieve(bag: DisposeBag, completion: @escaping (Ticker) -> Void) {
    self.webSocket.rx.didReceive
      .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .compactMap{ event -> Data? in
        guard case let .binary(response) = event else { return nil }
        return response
      }
      .map { try JSONDecoder().decode(Ticker.self, from: $0) }
      .catch{ _ in Observable.empty() }
      .subscribe(onNext: { ticker in
        completion(ticker)
      })
      .disposed(by: bag)
  }

  func bindWebSocketLifeCycle(coinList: BehaviorRelay<[Coin]>, bag: DisposeBag) {
    self.input.connectWebSocket
      .subscribe(onNext: { _ in
        self.webSocket.connect()
      })
      .disposed(by: bag)

    self.input.disConnectWebSocket
      .subscribe(onNext: { _ in
        self.webSocket.disconnect()
      })
      .disposed(by: bag)

    let onConnected = self.webSocket.rx.didReceive
      .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .compactMap{ event -> [String: String]? in
        guard case let .connected(response) = event else { return nil }
        return response
      }

    Observable.combineLatest(onConnected, coinList.filter{ !$0.isEmpty })
      .subscribe(onNext: { [weak self] _, coinList in
        self?.sendRequestTickers(coinList: coinList)
      })
      .disposed(by: bag)
  }

  func sendRequestTickers(coinList: [Coin]) {
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
    .compactMap{ String(data: $0, encoding: .utf8) }

    let params = "[" + parameterStrings.joined(separator: ",") + "]"
    guard let data = params.data(using: .utf8) else { return }
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String:AnyObject]] else { return }
    guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else { return }
    self.webSocket.write(data: jsonData)
  }
}
