//
//  Error.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/02.
//

import Foundation

enum APIError: Error, CustomStringConvertible {
  case urlError
  case networkError
  case parseError
  case requestAPIError
  case loadCoinNameError
  case loadCoinTickerError

  var description: String {
    switch self {
    case .networkError: return "네트워크가 불안정합니다."
    case .parseError: return "초기 데이터 파싱에 실패하였습니다."
    case .requestAPIError: return "잘못된 요청값입니다."
    case .urlError: return "잘못된 URL입니다."
    case .loadCoinNameError: return "코인 이름 로딩에 실패하였습니다."
    case .loadCoinTickerError: return "코인 가격 로딩에 실패하였습니다."
    }
  }

  var message: String? {
    switch self {
    case .networkError: return "잠시 후 다시 시도해주세요."
    default: return nil
    }
  }

}

enum valueError: Error, CustomStringConvertible {
  case invalidValueError

  var description: String {
    switch self {
    case .invalidValueError: return "유효하지 않은 값입니다."
    }
  }
}

enum WebSocketError: Error, CustomStringConvertible {
  case decodingError
  case connectError

  var description: String {
    switch self {
    case .decodingError: return "데이터 디코딩에 실패하였습니다."
    case .connectError: return "WebSocket 연결에 실패하였습니다."
    }
  }
}

enum inputCountError: Error, CustomStringConvertible {

  case isEmptyField
  case isNotNumber
  case inputtedZero
  case deficientDeposit
  case deficientHoldingCount

  var description: String {
    switch self {
    case .isEmptyField: return "매매할 수량을 입력해주세요."
    case .isNotNumber: return "숫자 외 다른 문자는 입력이 불가능합니다."
    case .inputtedZero: return "1 이상의 숫자만 입력 가능합니다."
    case .deficientDeposit: return "보유 중인 예수금이 부족합니다."
    case .deficientHoldingCount: return "보유 중인 수량이 부족합니다."
    }
  }

}
