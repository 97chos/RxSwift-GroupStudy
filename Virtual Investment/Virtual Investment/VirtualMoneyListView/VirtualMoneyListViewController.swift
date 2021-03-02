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
import RxSwift
import RxCocoa

class VirtualMoneyListViewController: UIViewController {

  // MARK: Properties

  private var coinList: BehaviorRelay = BehaviorRelay<[Coin]>(value: [])
  private var bag = DisposeBag()
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
    self.tableView.register(CoinCell.self, forCellReuseIdentifier: ReuseIdentifier.coinListCell)
    self.tableView.rowHeight = 60
  }

  private func initDataConfigure() {
    APIService().lookupCoinListRx()
      .subscribe(onNext: { coinList in
        self.coinList.accept(coinList)
        self.loadTickerData()
      }, onError: { error in
        switch error {
        case APIError.urlError:
          self.alert(title: "잘못된 URL입니다.", message: nil, completion: nil)
        case APIError.networkError:
          self.alert(title: "네트워크가 불안정합니다.", message: nil, completion: nil)
        case APIError.parseError:
          self.alert(title: "데이터 파싱에 실패하였습니다.", message: nil, completion: nil)
        default:
          break
        }
      })
      .disposed(by: bag)
  }

  private func loadTickerData() {
    var codeList: [String] = []
    self.coinList.value.forEach {
      codeList.append($0.code)
    }

    APIService().loadCoinsTickerDataRx(codes: codeList)
      .subscribe(onNext: { tickerList in
        self.loadingIndicator.startAnimating()
        var copyCoinList = self.coinList.value
        tickerList.enumerated().forEach { index, prices in
          copyCoinList[index].prices = prices
        }
        self.coinList.accept(copyCoinList)
        self.tableView.reloadData()
        self.loadingIndicator.stopAnimating()
      }, onError: { error in
        switch error as? APIError {
        case .urlError :
          self.alert(title: "호출 URL이 잘못되었습니다.", message: nil, completion: nil)
        case .networkError :
          self.alert(title: "네트워크가 불안정합니다.", message: "잠시 후 다시 시도해주세요.", completion: nil)
        case .parseError :
          self.alert(title: "초기 데이터 파싱에 실패하였습니다.", message: nil, completion: nil)
        default :
          break
        }
      })
      .disposed(by: bag)
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
    case .connected(_):
      let ticket = TicketField(ticket: "test")
      let format = FormatField(format: "SIMPLE")
      let type = TypeField(type: "ticker", codes: self.coinList.value.map{ $0.code }, isOnlySnapshot: false, isOnlyRealtime: true)

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
        let codeDic = Dictionary(grouping: self.coinList.value, by: { $0.code })

        guard var coin = codeDic[tickerData.code]?.first else { return }
        guard let index = self.coinList.value.firstIndex(where: { $0.code == coin.code }) else { return }
        coin.prices = tickerData

        var copyCoinList = self.coinList.value
        copyCoinList[index] = coin
        let indexInteger = coinList.value.index(0, offsetBy: index)

        self.coinList.accept(copyCoinList)
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
    return self.coinList.value.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.coinListCell, for: indexPath) as? CoinCell else {
      return UITableViewCell()
    }
    cell.set(coinData: self.coinList.value[indexPath.row])

    return cell
  }
}


// MARK: TableView Delegation

extension VirtualMoneyListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let vc = CoinInformationViewController(coin: self.coinList.value[indexPath.row])
    self.navigationController?.pushViewController(vc, animated: true)
    tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
  }
}
