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

  private var coinList: [Coin] = []
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

      let ticket = TicketField(ticket: "test")
      let format = FormatField(format: "SIMPLE")
      let type = TypeField(type: "ticker", codes: self.coinList.map{ $0.code }, isOnlySnapshot: false, isOnlyRealtime: true)

      let encoder = JSONEncoder()

      let parameterStrings = [
        try? encoder.encode(ticket),
        try? encoder.encode(format),
        try? encoder.encode(type)
      ]
      .compactMap{$0}
      .compactMap { String(data: $0, encoding: .utf8) }

      let params = "[" + parameterStrings.joined(separator: ",") + "]"

      let data = params.data(using: .utf8)
      let json = try! JSONSerialization.jsonObject(with: data!, options: []) as? [[String:AnyObject]]

      let jParams = try! JSONSerialization.data(withJSONObject: json, options: [])
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

        let codeDic = Dictionary(grouping: self.coinList, by: { coin in
          coin.code
        })

        guard var coin = codeDic[tickerData.code]?.first else { return }
        guard let index = self.coinList.firstIndex(where: { $0.code == coin.code }) else { return }
        
        coin.prices = tickerData
        self.coinList[index] = coin
        let indexInteger = coinList.index(0, offsetBy: index)

        DispatchQueue.main.async {
          self.tableView.reloadRows(at: [IndexPath(row: indexInteger, section: 0)], with: .none)
        }
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
    tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
  }
}
