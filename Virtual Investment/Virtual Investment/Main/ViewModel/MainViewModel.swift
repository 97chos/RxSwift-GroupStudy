//
//  MainViewModel.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/02.
//

import Foundation
import UIKit
import RxSwift


class MainViewModel {

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
      if let value = inputtedValue, let deposit = Double(value) {
        observer.onNext(deposit)
        observer.onCompleted()
      } else {
        observer.onError(valueError.invalidValueError)
      }
      return Disposables.create()
    })
  }


  // MARK: Make TabBarController

  func returnTabBarController() -> UITabBarController {
    let firstVC = UINavigationController(rootViewController: VirtualMoneyListViewController(viewModel: VirtualMoneyViewModel()))
    let secondVC = UINavigationController(rootViewController: InvestedViewController())

    firstVC.tabBarItem = UITabBarItem(title: "거래소", image: self.firstTabBarImage, tag: 0)
    secondVC.tabBarItem = UITabBarItem(title: "투자내역", image: self.secondTabBarImage, tag: 1)

    let tabBarController = UITabBarController()
    tabBarController.setViewControllers([firstVC,secondVC], animated: true)
    tabBarController.modalPresentationStyle = .fullScreen

    return tabBarController
  }
}
