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

enum ReueseIdentifier {
  static let coinListCell = "coinListCell"
  static let investedCoinListCell = "investedCoinListCell"
}

protocol changeCurrentPriceDelegation: class {
  func reloadData(price: Double?, code: String?)
}

class VirtualMoneyListViewController: UIViewController {

  // MARK: Properties

  private var coinList: [Coin]!
  weak var delegate: changeCurrentPriceDelegation!
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
  }

  override func viewWillAppear(_ animated: Bool) {
    self.connect()
    self.didReceive(event: .connected(["coinList":"list"]), client: webSocket)
  }

  override func viewWillDisappear(_ animated: Bool) {
    self.disconnect()
  }

  override func viewDidLayoutSubviews() {
    self.searchBar.frame.origin = CGPoint(x: 0, y: self.view.safeAreaInsets.top)
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.layout()
    self.initConfigure()
  }

  private func viewConfigure() {
    self.view.backgroundColor = .white
    self.title = "거래소"

    self.tableView.delegate = self
    self.tableView.dataSource = self

    self.tableView.register(CoinCell.self, forCellReuseIdentifier: ReueseIdentifier.coinListCell)
    self.tableView.rowHeight = 60
  }

  private func initConfigure() {
    self.coinList = APIService().lookupVirtualList()
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
    request.timeoutInterval = 100
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
                    ["type":"ticker","codes":["KRW-BTC"],"isOnlyRealtime":"true"]]

      let jParams = try! JSONSerialization.data(withJSONObject: params, options: [])
      client.write(string: String(data:jParams, encoding: .utf8)!, completion: nil)
      break
    case .disconnected(let reason, let code):
      print(".disconnected - \(reason), \(code)")
      break
    case .text(let string):
      print("text", string)

      break
    case .binary(let data):

      do {
        let decoder = JSONDecoder()
        let tickerData = try decoder.decode(ticker.self, from: data)

        print(tickerData)
      } catch {
        print(error.localizedDescription)
      }

      break
    case .error(let error):
      print(error?.localizedDescription ?? "")
      break
    default:
      break
    }
  }
}


extension VirtualMoneyListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.coinList.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: ReueseIdentifier.coinListCell, for: indexPath) as? CoinCell else {
      return UITableViewCell()
    }

    cell.set(coinData: self.coinList[indexPath.row])

    return cell
  }


}

extension VirtualMoneyListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let vc = CoinInformationViewController(coin: self.coinList[indexPath.row])
    self.navigationController?.pushViewController(vc, animated: true)
  }
}
