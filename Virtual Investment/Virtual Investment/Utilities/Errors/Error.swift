//
//  Error.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/02.
//

import Foundation

enum APIError: Error {
  case urlError
  case networkError
  case parseError
  case requestAPIError
}

enum valueError: Error {
  case invalidValueError
}

enum WebSocketError: Error {
  case decodingError
  case connectError
}
