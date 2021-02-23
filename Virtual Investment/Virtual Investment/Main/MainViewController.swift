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
    return imgView
  }()
  private let mainLabel: UILabel = {
    let label = UILabel()
    label.text = "사용할 가상 계좌 금액을 입력해주세요."
    label.font = .systemFont(ofSize: 15)
    label.sizeToFit()
    label.textColor = .white
    return label
  }()
  private let inputAmount: UITextField = {
    let textField = UITextField()
    textField.keyboardType = .numberPad
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


  // MARK: Configuration

  func configure() {
    self.viewConfigure()
    self.imageConfigure()
    self.layout()
  }

  func viewConfigure() {
    self.view.backgroundColor = #colorLiteral(red: 0.1220295802, green: 0.2095552683, blue: 0.5259671807, alpha: 1)
    self.navigationController?.navigationBar.isHidden = true
  }

  func imageConfigure() {
    self.mainImageView.image = UIImage(named: "upbit")
  }

  func layout() {
    self.view.addSubview(self.mainImageView)
    self.view.addSubview(self.mainLabel)
    self.view.addSubview(self.inputAmount)
    self.view.addSubview(self.nextButton)

    self.mainImageView.snp.makeConstraints {
      $0.top.equalTo(self.view.snp.top).inset(50)
      $0.centerX.equalToSuperview()
    }
  }

}
