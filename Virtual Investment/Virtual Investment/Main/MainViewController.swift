//
//  MainViewController.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/23.
//

import Foundation
import UIKit
import SnapKit

class MainViewController: UIViewController {

  // MARK: UI

  private let mainImageView: UIImageView = {
    let imgView = UIImageView()
    imgView.contentMode = .scaleAspectFit
    return imgView
  }()
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
  private let mainLabel: UILabel = {
    let label = UILabel()
    label.text = "사용할 가상 계좌 금액을 입력해주세요."
    label.font = .systemFont(ofSize: 18)
    label.sizeToFit()
    label.textColor = .white
    return label
  }()
  private let inputAmount: UITextField = {
    let textField = UITextField()
    textField.keyboardType = .numberPad
    textField.backgroundColor = .white
    textField.borderStyle = .roundedRect
    return textField
  }()
  private let nextButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("다음", for: .normal)
    button.setTitleColor(.white, for: .normal)
    return button
  }()


  // MARK: View LifeCycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configure()
  }


  // MARK: Events

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }


  // MARK: Actions

  @objc private func selectNextButton() {

    let inputedNumber = Float(self.inputAmount.text ?? "") ?? 0
    AmountData.shared.deposit = inputedNumber

    let firstVC = UINavigationController(rootViewController: VirtualMoneyListViewController())
    let secondVC = UINavigationController(rootViewController: InvestedViewController())

    firstVC.tabBarItem = UITabBarItem(title: "거래소", image: firstTabBarImage, tag: 0)
    secondVC.tabBarItem = UITabBarItem(title: "투자내역", image: secondTabBarImage, tag: 1)

    let tabBarController = UITabBarController()
    tabBarController.setViewControllers([firstVC,secondVC], animated: true)
    tabBarController.modalPresentationStyle = .fullScreen
    self.present(tabBarController, animated: true)
  }


  // MARK: Configuration

  private func configure() {
    self.viewConfigure()
    self.imageConfigure()
    self.layout()
  }

  private func viewConfigure() {
    self.view.backgroundColor = #colorLiteral(red: 0.1220295802, green: 0.2095552683, blue: 0.5259671807, alpha: 1)
    self.nextButton.addTarget(self, action: #selector(self.selectNextButton), for: .touchUpInside)
  }

  private func imageConfigure() {
    self.mainImageView.image = UIImage(named: "upbit")
  }

  private func layout() {
    self.view.addSubview(self.mainImageView)
    self.view.addSubview(self.mainLabel)
    self.view.addSubview(self.inputAmount)
    self.view.addSubview(self.nextButton)

    self.mainImageView.snp.makeConstraints {
      $0.top.equalTo(self.view.snp.top).inset(100)
      $0.width.equalToSuperview().multipliedBy(0.8)
      $0.centerX.equalToSuperview()
    }
    self.mainLabel.snp.makeConstraints {
      $0.top.equalTo(self.mainImageView.snp.bottom).offset(20)
      $0.centerX.equalToSuperview()
    }
    self.inputAmount.snp.makeConstraints {
      $0.top.equalTo(self.mainLabel.snp.bottom).offset(30)
      $0.centerX.equalToSuperview()
      $0.width.equalToSuperview().multipliedBy(0.6)
    }
    self.nextButton.snp.makeConstraints {
      $0.top.equalTo(self.inputAmount.snp.bottom).offset(50)
      $0.centerX.equalToSuperview()
    }
  }

}
