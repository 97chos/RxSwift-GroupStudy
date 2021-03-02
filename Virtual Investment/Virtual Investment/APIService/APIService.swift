//
//  APIService.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import Alamofire



class APIService {

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


  // MARK: Load Initializing Data

  func loadCoinsTickerData(codes: [String], completion: @escaping (Result<[ticker],Error>) -> Void) {

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
          completion(.success(priceListData))
        }
      } catch {
        completion(.failure(APIError.networkError))
      }
    }
  }
}
