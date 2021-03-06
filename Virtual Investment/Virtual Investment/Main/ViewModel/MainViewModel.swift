//
//  MainViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/02.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa


class MainViewModel {

  // MARK: Modules

  struct Input {
    let checkSet = BehaviorSubject<Void>(value: ())
  }


  // MARK: Properties

  private let bag = DisposeBag()
  let input = Input()

  
  // MARK: UI

  private lazy var firstTabBarImage: UIImage = {
    guard let image = UIImage(systemName: "dollarsign.square")?.withRenderingMode(.alwaysTemplate) else {
      return UIImage()
    }
    return image
  }()
  private lazy var secondTabBarImage: UIImage = {
    guard let image = UIImage(systemName: "cart")?.withRenderingMode(.alwaysTemplate) else {
      return UIImage()
    }
    return image
  }()


  // MARK: Rx Logic

  func checkInputtedValue(_ inputtedValue: String?) -> Observable<Double> {
    return Observable.create({ observer in
      if let value = inputtedValue, let deposit = Double(value), deposit > 0 {
        observer.onNext(deposit)
        observer.onCompleted()
      } else {
        observer.onError(valueError.invalidValueError)
      }
      return Disposables.create()
    })
  }


  // MARK: Bind

  func checkData() -> Bool {
    guard plist.bool(forKey: UserDefaultsKey.isCheckingUser) == true else { return false }
    guard let coinsData = plist.data(forKey: UserDefaultsKey.boughtCoinList) else { return false }
    guard let coins = try? PropertyListDecoder().decode([CoinInfo].self, from: coinsData) else { return false }

    let deposit = plist.double(forKey: UserDefaultsKey.remainingDeposit)

    AD.boughtCoins.accept(coins)
    AD.deposit.accept(deposit)
    return true
  }


  // MARK: Make TabBarController

  func returnTabBarController() -> UITabBarController {
    let firstVC = UINavigationController(rootViewController: VirtualMoneyListViewController(viewModel: VirtualMoneyViewModel(coinService: CoinService())))
    let secondVC = UINavigationController(rootViewController: InvestedViewController(viewModel: PurchasedViewModel(APIProtocol: APIService())))

    firstVC.tabBarItem = UITabBarItem(title: "거래소", image: self.firstTabBarImage, tag: 0)
    secondVC.tabBarItem = UITabBarItem(title: "투자내역", image: self.secondTabBarImage, tag: 1)

    let tabBarController = UITabBarController()
    tabBarController.setViewControllers([firstVC,secondVC], animated: true)
    tabBarController.modalPresentationStyle = .fullScreen

    return tabBarController
  }
}
