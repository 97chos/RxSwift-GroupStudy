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

  // MARK: Properties

  let conetext = CoreDataService.shared.context

  var coinList: BehaviorRelay = BehaviorRelay<[CoinInfo]>(value: [])
  var sections: BehaviorRelay<[CoinListSection]> = BehaviorRelay<[CoinListSection]>(value: [])
  let searchingText: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)

  var codeList: [String] = []
  private let bag = DisposeBag()
  private var request = URLRequest(url: URL(string: "wss://api.upbit.com/websocket/v1")!)
  private var APIService: APIServiceProtocol

  lazy var webSocket = WebSocket(request: self.request, certPinner: FoundationSecurity(allowSelfSigned: true))
  weak var delegate: WebSocektErrorDelegation?


  // MARK: Initializing

  init(APIProtocol: APIServiceProtocol) {
    self.APIService = APIProtocol
    self.bindSections()
  }


  // MARK: Functions

  private func bindSections() {
    Observable.combineLatest(self.coinList, self.searchingText) { coinList, searchingText -> [CoinInfo] in
      if let searchingText = searchingText {
        return coinList.filter{ $0.code.hasPrefix(searchingText) || $0.englishName.hasPrefix(searchingText) || $0.koreanName.hasPrefix(searchingText)}
      } else {
        return coinList
      }
    }
    .map{ [CoinListSection(header: "list", items: $0)] }
    .bind(to: self.sections)
    .disposed(by: bag)
  }

  func lookUpCoinList() -> Completable {
    var completedCoins: [CoinInfo] = []
    //    let missingPriceCoins = self.APIService.lookupCoinListRx()
    //      .flatMap{ Observable.from($0) }
    //
    //    let tickerData = Observable<Ticker>.create({ [weak self] oberver in
    //      guard let self = self else { return Disposables.create() }
    //      self.APIService.lookupCoinListRx()
    //        .subscribe(onNext: {
    //          self.APIService.loadCoinsTickerDataRx(coins: $0)
    //            .flatMap({ Observable.from($0) })
    //            .subscribe(onNext: {
    //              oberver.onNext($0)
    //            })
    //            .disposed(by: self.bag)
    //        })
    //        .disposed(by: self.bag)
    //      return Disposables.create()
    //    })
    //    return Completable.create(subscribe: { [weak self] observer in
    //      guard let self = self else { return Disposables.create() }
    //      Observable.zip(missingPriceCoins,tickerData) { coin, ticker -> CoinInfo in
    //        let coinInfo = CoinInfo(koreanName: coin.koreanName, englishName: coin.englishName, code: coin.code, holdingCount: 0, totalBoughtPrice: 0, prices: ticker)
    //        return coinInfo
    //      }
    //      .subscribe(onNext: { [weak self] in
    //        completedCoins.append($0)
    //        self?.coinList.accept(completedCoins)
    //      },onError: { error in
    //        observer(.error(error))
    //      })
    //      .disposed(by: self.bag)
    //
    //      return Disposables.create()
    //    })

    var maxCount = 0
    self.APIService.lookupCoinListRx()
      .flatMap{ coins -> Observable<CoinInfo> in
        maxCount = coins.count
        return self.APIService.loadCoinsTickerDataRx(coins: coins)
          .flatMap{ Observable.zip(Observable.from(coins), Observable.from($0)) { coin, ticker -> CoinInfo in
            let coinInfo = CoinInfo(koreanName: coin.koreanName, englishName: coin.englishName, code: coin.code, holdingCount: 0, totalBoughtPrice: 0, prices: ticker)
            return coinInfo
          }}
      }
      .subscribe(onNext: { [weak self] in
        completedCoins.append($0)
        if maxCount == completedCoins.count {
          self?.coinList.accept(completedCoins)
        }
      })
      .disposed(by: bag)

    return Completable.create(subscribe: { observer in
      observer(.completed)
      return Disposables.create()
    })
  }

  func setData() {
    AD.deposit
      .subscribe(onNext: { deposit in
        plist.set(deposit, forKey: UserDefaultsKey.remainingDeposit)
      })
      .disposed(by: bag)

    plist.set(true, forKey: UserDefaultsKey.isCheckingUser)
    plist.synchronize()

    AD.boughtCoins
      .subscribe(onNext: {
        print($0[0].holdingCount)
        guard let encodedData = try? PropertyListEncoder().encode($0) else { return }
        guard let decodeData = try? PropertyListDecoder().decode([CoinInfo].self, from: encodedData) else { return }
        print(decodeData[0].holdingCount)
        plist.set(encodedData, forKey: "aa")
      })
      .disposed(by: bag)

  }

  func resetData() {
    AD.boughtCoins.accept([])
    AD.deposit.accept(0.0)
    plist.set(false, forKey: UserDefaultsKey.isCheckingUser)
    plist.synchronize()
    coreData.clear()
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
        let tickerData = try decoder.decode(Ticker.self, from: data)
        let codeDic = Dictionary(grouping: listValue, by: { $0.code })

        guard var coin = codeDic[tickerData.code]?.first else { return }
        guard let index = listValue.firstIndex(where: { $0.code == coin.code }) else { return }
        coin.prices = tickerData

        listValue[index] = coin

        Observable.just(listValue)
          .bind(to: self.coinList)
          .disposed(by: bag)

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
