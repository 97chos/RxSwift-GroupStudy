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
import RxDataSources


class VirtualMoneyListViewController: UIViewController {

  // MARK: Properties

  let viewModel: VirtualMoneyViewModel
  let bag = DisposeBag()

  let dataSource = RxTableViewSectionedAnimatedDataSource<CoinListSection>(configureCell: { datasource, tableView, indexPath, item in
    guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.coinListCell, for: indexPath) as? CoinCell else {
      return UITableViewCell()
    }
    cell.set(coinData: item)
    return cell
  })


  // MARK: Bind

  private func bindSections() {
    self.viewModel.sections
      .bind(to: self.tableView.rx.items(dataSource: self.dataSource))
      .disposed(by: bag)

    self.tableView.rx.setDelegate(self)
      .disposed(by: bag)
  }

  private func bindSeraching() {
    self.searchBar.rx.text
      .bind(to: self.viewModel.searchingText)
      .disposed(by: bag)
  }


  // MARK: UI

  private lazy var searchBar: UISearchBar = {
    let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 56))
    searchBar.placeholder = "검색하기"
    searchBar.searchTextField.backgroundColor = .white
    searchBar.keyboardType = .webSearch
    searchBar.enablesReturnKeyAutomatically = false
    searchBar.delegate = self
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
  private lazy var barButton: UIBarButtonItem = {
    let button = UIBarButtonItem(title: "초기화", style: .plain, target: self, action: #selector(self.barButtonClicked))
    return button
  }()


  // MARK: Initializing

  init(viewModel: VirtualMoneyViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: View LifeCycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configure()
    self.bindSections()
    self.bindSeraching()
  }

  override func viewWillAppear(_ animated: Bool) {
    viewModel.connect()
  }

  override func viewWillDisappear(_ animated: Bool) {
    viewModel.disconnect()
  }

  override func viewDidLayoutSubviews() {
    self.layout()
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.initDataConfigure()
    self.viewModel.setData()
  }

  private func viewConfigure() {
    self.view.backgroundColor = .white
    self.title = "거래소"
    self.viewModel.delegate = self
    self.navigationItem.rightBarButtonItem = self.barButton

    self.tableView.register(CoinCell.self, forCellReuseIdentifier: ReuseIdentifier.coinListCell)
    self.tableView.rowHeight = 60
  }

  private func initDataConfigure() {
    self.viewModel.lookUpCoinList()
      .subscribe(onError: { [weak self] error in
        let errorType = error as? APIError
        self?.alert(title: errorType?.description, message: nil, completion: nil)
      })
      .disposed(by: bag)
  }

  @objc private func barButtonClicked() {
    self.alert(title: "구매한 코인 기록도 초기화됩니다. 초기화하시겠어요?", message: nil) {
      self.viewModel.resetData()
      self.dismiss(animated: true)
    }
  }


  // MARK: Layout

  private func layout() {
    self.view.addSubview(self.tableView)
    self.view.addSubview(self.searchBar)
    self.view.addSubview(self.loadingIndicator)
    self.searchBar.frame.origin = CGPoint(x: 0, y: self.view.safeAreaInsets.top)

    self.tableView.snp.makeConstraints {
      $0.leading.trailing.bottom.equalToSuperview()
      $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(self.searchBar.frame.height)
    }
  }
}


// MARK: TableView Delegation

extension VirtualMoneyListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let coin = viewModel.sections.value.first?.items[indexPath.row] else { return }

    let vc = CoinInformationViewController(viewModel: CoinInformationViewModel(coin: coin))
    self.navigationController?.pushViewController(vc, animated: true)
    self.view.endEditing(true)
    tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
  }

  func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    return 50
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.view.endEditing(true)
  }
}


// MARK: SearchBar Delegation

extension VirtualMoneyListViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.view.endEditing(true)
  }
}


// MARK: WebSocket Delegation

extension VirtualMoneyListViewController: WebSocektErrorDelegation {
  func sendFailureResult(_ errorType: WebSocketError) {
    self.alert(title: errorType.description, message: nil, completion: nil)
  }
}
