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

//class ViewController {
//  private var _view: UIView?
//  var view: UIView! {
//    get {
//      if _view == nil {
//        self.loadView()
//      }
//      return self._view
//    }
//    set {
//      self._view = newValue
//    }
//  }
//
//  func loadView() {
//    self._view = UIView()
//    self.viewDidLoad()
//  }
//
//  func viewDidLoad() {
//
//  }
//}

class VirtualMoneyListViewController: UIViewController {

  // MARK: Properties

  let viewModel: VirtualMoneyViewModel
  let bag = DisposeBag()


  // MARK: UI

  private lazy var searchBar: UISearchBar = {
    let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 56))
    searchBar.placeholder = "검색하기"
    searchBar.searchTextField.backgroundColor = .white
    searchBar.keyboardType = .webSearch
    searchBar.enablesReturnKeyAutomatically = false
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
    self.configureViews()
    self.layoutViews()
    self.bind()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.searchBar.frame.origin = CGPoint(x: 0, y: self.view.safeAreaInsets.top)
  }


  // MARK: Configuration

  private func configureViews() {
    self.view.backgroundColor = .white
    self.title = "거래소"
    self.navigationItem.rightBarButtonItem = self.barButton
    self.configureTableView()
  }

  private func configureTableView() {
    self.tableView.register(CoinCell.self, forCellReuseIdentifier: ReuseIdentifier.coinListCell)
    self.tableView.rowHeight = 60
    self.tableView.tableFooterView = UIView()
  }

  @objc private func barButtonClicked() {
    self.alert(title: "구매한 코인 기록도 초기화됩니다. 초기화하시겠어요?", message: nil) { [weak self] in
      self?.viewModel.input.didReseted.onNext(())
      self?.dismiss(animated: true)
    }
  }


  // MARK: Bind

  private func bind() {
    self.bindInitialize()
    self.bindSections()
    self.bindWebSocketConnection()
    self.bindSelectCoin()
    self.bindDesposit()
    self.bindSearchText()
  }

  private func bindInitialize() {
    self.rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
      .map { _ in }
      .take(1)
      .bind(to: self.viewModel.input.didInitialized)
      .disposed(by: self.bag)
  }

  private func bindSections() {
    self.viewModel.output.coinCellViewModels
      .bind(to: self.tableView.rx.items(cellIdentifier: ReuseIdentifier.coinListCell, cellType: CoinCell.self)) { index, viewModel, cell in
        cell.set(viewModel: viewModel)
      }
      .disposed(by: self.bag)
  }

  private func bindWebSocketConnection() {
    self.rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
      .map { _ in }
      .bind(to: self.viewModel.input.connectWebSocket)
      .disposed(by: self.bag)

    self.rx.methodInvoked(#selector(UIViewController.viewDidDisappear(_:)))
      .map { _ in }
      .bind(to: self.viewModel.input.disConnectWebSocket)
      .disposed(by: self.bag)
  }

  private func bindSelectCoin() {
    self.tableView.rx.modelSelected(CoinCellViewModel.self)
      .flatMapLatest { viewModel -> Observable<CoinInfo> in
        viewModel.tickerObservable
          .take(1)
          .map { ticker in
          CoinInfo(coin: viewModel.coin, ticker: ticker)
        }
      }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] coinInfo in
        let viewController = CoinInformationViewController(viewModel: CoinInformationViewModel(coin: coinInfo))
        self?.navigationController?.pushViewController(viewController, animated: true)
      })
      .disposed(by: self.bag)
  }

  private func bindDesposit() {
    AD.deposit
      .subscribe(onNext: {
        plist.set($0, forKey: UserDefaultsKey.remainingDeposit)
      })
      .disposed(by:bag)
  }

  private func bindSearchText() {
    self.searchBar.rx.text
      .bind(to: self.viewModel.input.inputtedSearchText)
      .disposed(by: bag)
  }

  // MARK: Layout

  private func layoutViews() {
    self.view.addSubview(self.tableView)
    self.view.addSubview(self.searchBar)
    self.view.addSubview(self.loadingIndicator)

    self.tableView.snp.makeConstraints {
      $0.leading.trailing.bottom.equalToSuperview()
      $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(self.searchBar.frame.height)
    }
  }
}
