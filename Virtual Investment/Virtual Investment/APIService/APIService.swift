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
  func loadCoinsTickerDataRx(coins: [Coin]) -> Observable<[ticker]>
  func loadCoinTickerDataRx(coin: Coin) -> Observable<Coin>

}

class APIService: APIServiceProtocol {

  // MARK: Lookup Virtual List

  func lookupCoinList(completion: @escaping (Result<[Coin],Error>) -> Void) {
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
        completion(.failure(APIError.parseError))
      }
    } catch {
      completion(.failure(APIError.networkError))
    }
  }

  func lookupCoinListRx() -> Observable<[Coin]> {
    return Observable.create({ observer in
      self.lookupCoinList { result in
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

  func loadCoinsTickerData(coins: [Coin], completion: @escaping (Result<[ticker],Error>) -> Void) {
    let codes = coins.map{ $0.code }
    let codeList = codes.joined(separator: ",")
    var priceListData: [ticker] = []

    let param: Parameters = ["markets" : codeList]

    guard let url: URL = URL(string: "https://api.upbit.com/v1/ticker") else { completion(.failure(APIError.urlError))
      return
    }

    AF.request(url, method: .get, parameters: param, encoding: URLEncoding.queryString).responseJSON { response in
      do {
        guard let result = try response.result.get() as? [[String:Any]] else {
          completion(.failure(APIError.parseError))
          return
        }

        result.forEach {
          guard let currentPrice = $0["trade_price"] as? Double else { return }
          guard let code = $0["market"] as? String else { return }
          guard let highPrice = $0["high_price"] as? Double else { return }
          guard let lowPrice = $0["low_price"] as? Double else { return }
          let coinData = ticker(currentPrice: currentPrice, code: code, highPrice: highPrice, lowPrice: lowPrice)
          priceListData.append(coinData)
        }
        completion(.success(priceListData))
      } catch {
        completion(.failure(APIError.networkError))
      }
    }
  }

  func loadCoinsTickerDataRx(coins: [Coin]) -> Observable<[ticker]> {
    return Observable.create({ observer in
      self.loadCoinsTickerData(coins: coins) { result in
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


  // MARK: Load Coin Ticker Data

  func loadCoinTickerData(coin: Coin, completion: @escaping (Result<Coin,Error>) -> Void) {
    var mutableCoin = coin
    let code = coin.code
    let param: Parameters = ["markets" : code]

    guard let url: URL = URL(string: "https://api.upbit.com/v1/ticker") else { completion(.failure(APIError.urlError))
      return
    }

    AF.request(url, method: .get, parameters: param, encoding: URLEncoding.queryString).responseJSON { response in
      do {
        guard let resultArray = try response.result.get() as? [[String:Any]] else {
          completion(.failure(APIError.parseError))
          return
        }

        let result = resultArray.first

        guard let currentPrice = result?["trade_price"] as? Double else { return }
        guard let code = result?["market"] as? String else { return }
        guard let highPrice = result?["high_price"] as? Double else { return }
        guard let lowPrice = result?["low_price"] as? Double else { return }

        let coinData = ticker(currentPrice: currentPrice, code: code, highPrice: highPrice, lowPrice: lowPrice)

        mutableCoin.prices = coinData

        completion(.success(mutableCoin))
      } catch {
        print(error.localizedDescription)
        completion(.failure(APIError.networkError))
      }
    }
  }

  func loadCoinTickerDataRx(coin: Coin) -> Observable<Coin> {
    return Observable.create({ observer in
      self.loadCoinTickerData(coin: coin) { result in
        switch result {
        case .success(let coin):
          observer.onNext(coin)
          observer.onCompleted()
        case .failure(let error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    })
  }

}
