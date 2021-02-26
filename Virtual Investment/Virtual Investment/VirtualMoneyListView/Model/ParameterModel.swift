//
//  ParameterModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/26.
//

import Foundation

struct RequestParamOnConnected {
  let ticket: String
  let format: String
  let type: String
}

struct TicketField: Codable {
  let ticket: String
}

struct FormatField: Codable {
  let format: String?
}

struct TypeField: Codable {
  let type: String
  let codes: [String]
  let isOnlySnapshot: Bool?
  let isOnlyRealtime: Bool?
}
