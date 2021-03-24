//
//  InvestedViewController.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/24.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

enum checkProfit {
  case equal
  case profit
  case loss
}

class InvestedViewController: UIViewController {

  // MARK: Properties

  private var viewModel: PurchasedViewModel
  private let bag = DisposeBag()


  // MARK: UI

  private let depositLabelTitle: UILabel = {
    let label = UILabel()
    label.text = "총 예수금"
    label.font = .boldSystemFont(ofSize: 20)
    label.sizeToFit()
    return label
  }()
  private lazy var depositLabel: UILabel = {
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 20)
    label.textAlignment = .right
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  private let evaluatedLabelTitle: UILabel = {
    let label = UILabel()
    label.text = "평가 금액"
    label.font = .boldSystemFont(ofSize: 20)
    label.sizeToFit()
    return label
  }()
  private lazy var evaluatedLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .right
    label.font = .boldSystemFont(ofSize: 25)
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  private let invesetmentLabelTitle: UILabel = {
    let label = UILabel()
    label.text = "투자 금액"
    label.font = .boldSystemFont(ofSize: 20)
    label.sizeToFit()
    return label
  }()
  private lazy var investmentLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .right
    label.font = .boldSystemFont(ofSize: 25)
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  private let depositContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray6
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.white.cgColor
    return view
  }()
  private let evaluatedContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray6
    return view
  }()
  private let investmentContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray6
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.white.cgColor
    return view
  }()
  private lazy var allContainerView: UIView = {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * 0.2))
    view.backgroundColor = .systemBackground
    return view
  }()
  private let tableView: UITableView = {
    let tableView = UITableView()
    return tableView
  }()


  // MARK: Initializing

  init(viewModel: PurchasedViewModel) {
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
  }

  override func viewWillAppear(_ animated: Bool) {
    self.tableView.reloadData()
    self.getCurrentPrice()
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.layout()
    self.tableViewConfigure()
    self.RxConfigure()
  }

  private func viewConfigure() {
    self.view.backgroundColor = .systemBackground
    self.title = "투자 내역"
  }

  private func tableViewConfigure() {
    self.tableView.register(InvestedCoinCell.self, forCellReuseIdentifier: ReuseIdentifier.investedCoinListCell)
    self.tableView.register(InvestedSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifier.investeSectionHeaderView)
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.rowHeight = 60
  }

  private func RxConfigure() {
    self.bindPrices()
  }

  private func bindPrices() {
    AD.deposit.asObservable()
      .map{ $0.currenyKRW() }
      .bind(to: self.depositLabel.rx.text)
      .disposed(by: bag)

    AD.evaluatedPrice
      .map{ $0.currenyKRW() }
      .bind(to: self.evaluatedLabel.rx.text)
      .disposed(by: bag)

    AD.investedPrice
      .map{ $0.currenyKRW() }
      .bind(to: self.investmentLabel.rx.text)
      .disposed(by: bag)

    Observable.combineLatest(
      AD.evaluatedPrice,
      AD.investedPrice,
      resultSelector: { [weak self] in
        self?.viewModel.checkProfit($0, $1) }
    )
    .subscribe(onNext: { [weak self] result in
      switch result {
      case .equal:
        self?.evaluatedLabel.textColor = .black
      case .loss:
        self?.evaluatedLabel.textColor = .systemBlue
      case .profit:
        self?.evaluatedLabel.textColor = .systemRed
      case .none:
        self?.evaluatedLabel.textColor = .black
      }
    })
    .disposed(by: bag)
  }


  // MARK: Functions

  private func getCurrentPrice() {
    viewModel.getCurrentPrice()
      .subscribe { [weak self] completable in
        switch completable {
        case .completed:
          break
        case .error(let error):
          let errorType = error as? APIError
          self?.alert(title: errorType?.description, message: errorType?.message, completion: nil)
        }
      }
      .disposed(by: bag)
  }

  // MARK: Layout

  private func layout() {
    self.depositContainerView.addSubview(self.depositLabelTitle)
    self.depositContainerView.addSubview(self.depositLabel)
    self.evaluatedContainerView.addSubview(self.evaluatedLabelTitle)
    self.evaluatedContainerView.addSubview(self.evaluatedLabel)
    self.investmentContainerView.addSubview(self.invesetmentLabelTitle)
    self.investmentContainerView.addSubview(self.investmentLabel)
    self.allContainerView.addSubview(self.depositContainerView)
    self.allContainerView.addSubview(self.evaluatedContainerView)
    self.allContainerView.addSubview(self.investmentContainerView)
    self.view.addSubview(self.tableView)
    self.tableView.tableHeaderView = allContainerView

    self.tableView.snp.makeConstraints {
      $0.edges.equalTo(self.view.safeAreaLayoutGuide)
    }
    self.investmentContainerView.snp.makeConstraints {
      $0.width.equalToSuperview().multipliedBy(0.5)
      $0.height.equalToSuperview().multipliedBy(0.6)
      $0.leading.equalToSuperview()
      $0.top.equalToSuperview()
    }
    self.evaluatedContainerView.snp.makeConstraints {
      $0.width.equalToSuperview().multipliedBy(0.5)
      $0.height.equalTo(self.investmentContainerView.snp.height)
      $0.trailing.equalToSuperview()
      $0.top.equalToSuperview()
    }
    self.depositContainerView.snp.makeConstraints {
      $0.width.equalToSuperview()
      $0.height.equalToSuperview().multipliedBy(0.4)
      $0.leading.equalToSuperview()
      $0.top.equalTo(self.investmentContainerView.snp.bottom)
    }
    self.invesetmentLabelTitle.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview().offset(-25)
    }
    self.evaluatedLabelTitle.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(10)
      $0.centerY.equalToSuperview().offset(-25)
    }
    self.depositLabelTitle.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(10)
      $0.width.equalToSuperview().multipliedBy(0.35)
      $0.centerY.equalToSuperview()
    }
    self.evaluatedLabel.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(10)
      $0.width.equalToSuperview().multipliedBy(0.9)
      $0.centerY.equalToSuperview().offset(20)
    }
    self.investmentLabel.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(10)
      $0.width.equalToSuperview().multipliedBy(0.9)
      $0.centerY.equalToSuperview().offset(20)
    }
    self.depositLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.width.equalToSuperview().multipliedBy(0.6)
      $0.trailing.equalToSuperview().inset(10)
    }
  }
}

extension InvestedViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return AD.boughtCoins.value.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.investedCoinListCell , for: indexPath) as? InvestedCoinCell else {
      return UITableViewCell()
    }
    cell.set(coinIndex: indexPath.row)

    return cell
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifier.investeSectionHeaderView) as? InvestedSectionHeaderView else {
      return UIView()
    }
    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 50
  }
}

extension InvestedViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let informationVC = CoinInformationViewController(viewModel: CoinInformationViewModel(coin: AD.boughtCoins.value[indexPath.row]))
    self.navigationController?.pushViewController(informationVC, animated: true)
    tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
  }
}
