//
//  MainViewController.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/23.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {

  // MARK: Properties

  var disposeBag = DisposeBag()
  var viewModel: MainViewModel

  
  // MARK: UI

  private let mainImageView: UIImageView = {
    let imgView = UIImageView()
    imgView.contentMode = .scaleAspectFit
    return imgView
  }()
  private let mainLabel: UILabel = {
    let label = UILabel()
    label.text = "사용할 가상 계좌 금액을 입력해주세요."
    label.font = .systemFont(ofSize: 18)
    label.sizeToFit()
    label.textColor = .white
    return label
  }()
  private let inputDeposit: UITextField = {
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
    button.setTitle("금액을 입력해주세요.", for: .disabled)
    button.setTitleColor(.systemGray4, for: .disabled)
    return button
  }()


  // MARK: Initializing

  init(viewModel: MainViewModel) {
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
    self.isNumericCheck()
  }

  override func viewWillDisappear(_ animated: Bool) {
    self.disposeBag = DisposeBag()
  }


  // MARK: Events

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }


  // MARK: Actions

  @objc private func selectNextButton() {
    self.viewModel.checkInputtedValue(self.inputDeposit.text)
      .subscribe(onNext: { [weak self] in
        AmountData.shared.deposit = $0
        self?.present(self?.viewModel.returnTabBarController() ?? UITabBarController(), animated: true)
      }, onError: { [weak self] error in
        switch error {
        case valueError.invalidValueError:
          self?.alert(title: "숫자만 입력 가능합니다.", message: nil, completion: nil)
        default:
          break
        }
      })
      .disposed(by: disposeBag)
  }


  // MARK: Rx Logic

  private func isNumericCheck() {
    self.inputDeposit.rx.text.orEmpty
      .map { !$0.isEmpty }
      .bind(to: self.nextButton.rx.isEnabled)
      .disposed(by: disposeBag)
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
    self.view.addSubview(self.inputDeposit)
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
    self.inputDeposit.snp.makeConstraints {
      $0.top.equalTo(self.mainLabel.snp.bottom).offset(30)
      $0.centerX.equalToSuperview()
      $0.width.equalToSuperview().multipliedBy(0.6)
    }
    self.nextButton.snp.makeConstraints {
      $0.top.equalTo(self.inputDeposit.snp.bottom).offset(50)
      $0.centerX.equalToSuperview()
    }
  }
}
