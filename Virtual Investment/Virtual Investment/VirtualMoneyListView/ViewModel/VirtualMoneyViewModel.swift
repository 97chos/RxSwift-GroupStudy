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

  func lookUpCoinList(completion: @escaping (Result<(),Error>) -> Void) {
    self.APIService.lookupCoinListRx()
      .observe(on: MainScheduler.asyncInstance)
      .subscribe(onNext: { coinList in
        self.coinList.accept(coinList)
        completion(.success(()))
      }, onError: { error in
        completion(.failure(error))
      })
      .disposed(by: bag)
  }

  func loadTickerData(completion: @escaping (Result<(),Error>) -> Void) {
    self.extractCodeList()
    self.APIService.loadCoinsTickerDataRx(codes: self.codeList)
      .observe(on: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] tickerList in
        self?.coinList
          .distinctUntilChanged()
          .map{ arr -> [Coin] in
            var list = arr
            tickerList.enumerated().forEach{ index, prices in
              list[index].prices = prices
            }
            return list
          }
          .subscribe(onNext: {
            self?.coinList.accept($0)
          })
          .disposed(by: self?.bag ?? DisposeBag())
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
        var listValue = self.coinList.value
        let decoder = JSONDecoder()
        let tickerData = try decoder.decode(ticker.self, from: data)
        let codeDic = Dictionary(grouping: listValue, by: { $0.code })

        guard var coin = codeDic[tickerData.code]?.first else { return }
        guard let index = listValue.firstIndex(where: { $0.code == coin.code }) else { return }
        coin.prices = tickerData

        listValue[index] = coin
        let indexInteger = listValue.index(0, offsetBy: index)

        self.coinList.accept(listValue)
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
