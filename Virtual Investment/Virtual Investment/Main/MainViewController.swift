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
  private let textField: UITextField = {
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

}
