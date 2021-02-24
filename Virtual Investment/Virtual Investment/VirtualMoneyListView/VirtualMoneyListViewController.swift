//
//  VirtualMoneyListViewController.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import UIKit
import SnapKit
import Starscream

class VirtualMoneyListViewController: UIViewController {

  // MARK: Properties

  var request = URLRequest(url: URL(string: "wss://api.upbit.com/websocket/v1")!)
  lazy var webSocket = WebSocket(request: self.request, certPinner: FoundationSecurity(allowSelfSigned: true))


  // MARK: UI

  private lazy var searchBar: UISearchBar = {
    let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 56))
    searchBar.placeholder = "검색하기"
    searchBar.searchTextField.backgroundColor = .white
    searchBar.keyboardType = .asciiCapable
    return searchBar
  }()
  private let tableView: UITableView = {
    let tableView = UITableView()
    return tableView
  }()


  // MARK: View LifeCycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configure()
    self.connect()
    self.didReceive(event: .connected(["이게":"뭐지"]), client: webSocket)
  }

  override func viewDidLayoutSubviews() {
    self.searchBar.frame.origin = CGPoint(x: 0, y: self.view.safeAreaInsets.top)
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.layout()
  }

  private func viewConfigure() {
    self.view.backgroundColor = .white
    self.title = "거래소"
  }

  private func layout() {
    self.view.addSubview(self.tableView)
    self.view.addSubview(self.searchBar)

    self.tableView.snp.makeConstraints {
      $0.leading.trailing.bottom.equalToSuperview()
      $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(self.searchBar.frame.height)
    }
  }
}

extension VirtualMoneyListViewController: WebSocketDelegate {

  func connect() {
    request.timeoutInterval = 10
    webSocket.delegate = self
    webSocket.connect()
  }

  func disconnect() {
    webSocket.disconnect()
  }

  func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch(event) {
    case .connected(let headers):
      print(".connected - \(headers)")


      let params = [["ticket":"test"],
                    ["format":"SIMPLE"],
                    ["type":"ticker","codes":["KRW-BTC"],"isOnlyRealtime":"true"],
                    ["type":"trade","codes":["KRW-BTC"]]]

      let jParams = try! JSONSerialization.data(withJSONObject: params, options: [])
      client.write(string: String(data:jParams, encoding: .utf8)!, completion: nil)
      break
    case .disconnected(let reason, let code):
      print(".disconnected - \(reason), \(code)")
      break
    case .text(let string):
      print("text", string)
      //parse(data: string.data(using: .utf8)!)

      break
    case .binary(let data):

      //parse(data: data)

      break
    case .error(let error):
      print(error?.localizedDescription ?? "")
      break
    default:
      break
    }
  }
}

