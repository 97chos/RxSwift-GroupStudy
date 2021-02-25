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

  func lookupVirtualList() -> [Coin] {
    guard let url: URL = URL(string:"https://api.upbit.com/v1/market/all") else {
      return []
    }
    do {
      let response = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      do {
        let data = try decoder.decode([Coin].self, from: response)
        return data
      } catch {
        print(error.localizedDescription)
        return []
      }
    } catch {
      return []
    }
  }
}
