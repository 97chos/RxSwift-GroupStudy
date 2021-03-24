//
//  APIService.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import Alamofire
import RxSwift

protocol APIServiceProtocol {
  func lookupCoinListRx() -> Observable<[Coin]>
  func loadCoinsTickerDataRx(coins: [Coin]) -> Observable<[Ticker]>
}


class APIService: APIServiceProtocol {

  // MARK: Lookup Virtual List

  func lookupCoinList(completion: @escaping (Result<[Coin],APIError>) -> Void) {
    guard let url: URL = URL(string:"https://api.upbit.com/v1/market/all") else {
      completion(.failure(APIError.urlError))
      return
    }
    do {
      let response = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      do {
        let data = try decoder.decode([Coin].self, from: response)
        completion(.success(data))
      } catch {
        completion(.failure(.parseError))
      }
    } catch {
      completion(.failure(.networkError))
    }
  }

  func lookupCoinListRx() -> Observable<[Coin]> {
    return Observable.create({ [weak self] observer in
      self?.lookupCoinList { result in
        switch result {
        case .success(let coinList):
          observer.onNext(coinList)
          observer.onCompleted()
        case .failure(let error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    })
  }


  // MARK: Load Coins Ticker List Data

  func loadCoinsTickerData(coins: [Coin], completion: @escaping (Result<[Ticker],APIError>) -> Void) {
    let codes = coins.map{ $0.code }
    let codeList = codes.joined(separator: ",")
    var priceListData: [Ticker] = []

    let param: Parameters = ["markets" : codeList]

    guard let url: URL = URL(string: "https://api.upbit.com/v1/ticker") else {
      completion(.failure(.urlError))
      return
    }

    AF.request(url, method: .get, parameters: param, encoding: URLEncoding.queryString).responseJSON { response in
      do {
        guard let result = try response.result.get() as? [[String:Any]] else {
          completion(.failure(.parseError))
          return
        }

        result.forEach {
          guard let currentPrice = $0["trade_price"] as? Double else { return }
          guard let code = $0["market"] as? String else { return }
          guard let highPrice = $0["high_price"] as? Double else { return }
          guard let lowPrice = $0["low_price"] as? Double else { return }
          let coinData = Ticker(currentPrice: currentPrice, code: code, highPrice: highPrice, lowPrice: lowPrice)
          priceListData.append(coinData)
        }
        completion(.success(priceListData))

      } catch {
        completion(.failure(.networkError))
      }
    }
  }

  func loadCoinsTickerDataRx(coins: [Coin]) -> Observable<[Ticker]> {
    return Observable.create({ [weak self] observer in
      self?.loadCoinsTickerData(coins: coins) { result in
        switch result {
        case .success(let tickerList):
          observer.onNext(tickerList)
          observer.onCompleted()
        case .failure(let error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    })
  }
}
