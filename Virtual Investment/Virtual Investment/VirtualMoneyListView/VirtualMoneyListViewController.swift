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

  let viewModel: VirtualMoneyViewModel
  let bag = DisposeBag()


  // MARK: Initializing

  init(viewModel: VirtualMoneyViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


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
    viewModel.connect()
    viewModel.didReceive(event: .connected(["coinList":"list"]), client: viewModel.webSocket)
  }

  override func viewWillDisappear(_ animated: Bool) {
    viewModel.disconnect()
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
    self.viewModel.delegate = self

    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.register(CoinCell.self, forCellReuseIdentifier: ReuseIdentifier.coinListCell)
    self.tableView.rowHeight = 60
  }

  private func initDataConfigure() {
    APIService().lookupCoinListRx()
      .subscribe(onNext: { coinList in
        self.viewModel.coinList.accept(coinList)
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
    viewModel.coinList.value.forEach {
      codeList.append($0.code)
    }

    APIService().loadCoinsTickerDataRx(codes: codeList)
      .subscribe(onNext: { [weak self] tickerList in
        self?.loadingIndicator.startAnimating()
        var copyCoinList = self?.viewModel.coinList.value
        tickerList.enumerated().forEach { index, prices in
          copyCoinList?[index].prices = prices
        }
        self?.viewModel.coinList.accept(copyCoinList ?? [])
        self?.tableView.reloadData()
        self?.loadingIndicator.stopAnimating()
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


// MARK: TableView DataSource

extension VirtualMoneyListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.coinList.value.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.coinListCell, for: indexPath) as? CoinCell else {
      return UITableViewCell()
    }
    cell.set(coinData: viewModel.coinList.value[indexPath.row])
    return cell
  }
}


// MARK: TableView Delegation

extension VirtualMoneyListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let vc = CoinInformationViewController(coin: viewModel.coinList.value[indexPath.row])
    self.navigationController?.pushViewController(vc, animated: true)
    tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
  }
}

extension VirtualMoneyListViewController: WebSocektErrorDelegation {
  func sendSuccessResult(_ index: Int) {
    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
  }

  func sendFailureResult(_ errorType: WebSocketError) {
    switch errorType {
    case .connectError:
      self.alert(title: "WebSocket 연결에 실패하였습니다.", message: nil, completion: nil)
    case .decodingError:
      self.alert(title: "JSON Decoding에 실패하였습니다.", message: nil, completion: nil)
    }
  }
}
