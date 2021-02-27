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


class VirtualMoneyListViewController: UIViewController {

  // MARK: Properties

  private var coinList: [Coin] = []
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
  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.tintColor = .darkGray
    indicator.hidesWhenStopped = true
    return indicator
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
    self.initDataConfigure()
  }

  private func viewConfigure() {
    self.view.backgroundColor = .white
    self.title = "거래소"

    self.tableView.delegate = self
    self.tableView.dataSource = self

    self.tableView.register(CoinCell.self, forCellReuseIdentifier: ReueseIdentifier.coinListCell)
    self.tableView.rowHeight = 60
  }

  private func initDataConfigure() {
    self.coinList = APIService().lookupVirtualList()

    var codeList: [String] = []
    self.coinList.forEach {
      codeList.append($0.code)
    }

    APIService().loadCoinsData(codes: codeList) { result in
      switch result {
      case .success(let coinPriceList) :
        self.loadingIndicator.startAnimating()
        coinPriceList.enumerated().forEach { index, prices in
          self.coinList[index].prices = prices
        }
        self.tableView.reloadData()
        self.loadingIndicator.stopAnimating()
      case .failure(let error) :
        switch error {
        case APIError.urlError :
          self.alert(title: "호출 URL이 잘못되었습니다.", message: nil, completion: nil)
        case APIError.networkError :
          self.alert(title: "네트워크가 불안정합니다.", message: "잠시 후 다시 시도해주세요.", completion: nil)
        case APIError.parseError :
          self.alert(title: "초기 데이터 파싱에 실패하였습니다.", message: nil, completion: nil)
        default :
          break
        }
      }
    }
  }


  // MARK: Layout

  private func layout() {
    self.view.addSubview(self.tableView)
    self.view.addSubview(self.searchBar)
    self.view.addSubview(self.loadingIndicator)

    self.tableView.snp.makeConstraints {
      $0.leading.trailing.bottom.equalToSuperview()
      $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(self.searchBar.frame.height)
    }
  }
}


// MARK: WebScoket Delegation

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

      guard let data = params.data(using: .utf8) else {
        return
      }
      guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String:AnyObject]] else {
        return
      }
      guard let jParams = try? JSONSerialization.data(withJSONObject: json, options: []) else {
        return
      }
      client.write(string: String(data:jParams, encoding: .utf8) ?? "", completion: nil)
      break
    case .binary(let data):
      
      do {
        let decoder = JSONDecoder()
        let tickerData = try decoder.decode(ticker.self, from: data)
        let codeDic = Dictionary(grouping: self.coinList, by: { $0.code })

        guard var coin = codeDic[tickerData.code]?.first else { return }
        guard let index = self.coinList.firstIndex(where: { $0.code == coin.code }) else { return }
        
        coin.prices = tickerData
        self.coinList[index] = coin
        let indexInteger = coinList.index(0, offsetBy: index)

        DispatchQueue.main.async {
          self.tableView.reloadRows(at: [IndexPath(row: indexInteger, section: 0)], with: .none)
        }
      } catch {
        self.alert(title: "JSON Decoding에 실패하였습니다.", message: nil, completion: nil)
      }

      break
    case .error(let error):
      self.alert(title: "WebSocket 연결에 실패하였습니다.", message: "\(error?.localizedDescription ?? "")", completion: nil)
      break
    default:
      break
    }
  }
}


// MARK: TableView DataSource

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


// MARK: TableView Delegation

extension VirtualMoneyListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let vc = CoinInformationViewController(coin: self.coinList[indexPath.row])
    self.navigationController?.pushViewController(vc, animated: true)
    tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
  }
}
