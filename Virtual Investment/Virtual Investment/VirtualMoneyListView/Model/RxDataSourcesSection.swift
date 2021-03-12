//
//  RxDataSourcesSection.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/05.
//

import Foundation
import RxDataSources

struct SampleSectionItem {

    public enum SectionType: Int {
        case today
        case week
        case none
    }

    var sectionType: SectionType
    var items: [String]

    static func getSctionType(_ rowValue: Int) -> SectionType {
        var type: SectionType

        switch rowValue {
        case SectionType.today.rawValue:
            type = SectionType.today
            break

        case SectionType.week.rawValue:
            type = SectionType.week
            break

        default:
            type = SectionType.none
            break
        }
        return type
    }
}

extension SampleSectionItem: SectionModelType {
    typealias Item = String

    init(original: SampleSectionItem, items: [Item]) {
        self = original
        self.items = items
    }
}


import UIKit
import RxCocoa
import RxSwift
import RxDataSources

// property 선언
class SampleSectionTableViewController: UIViewController {

    @IBOutlet var tableView: UITableView!

    private let disposeBag = DisposeBag()

    private var tableViewItems = BehaviorRelay(value: [SampleSectionItem]())

    private var dataSource: RxTableViewSectionedReloadDataSource<SampleSectionItem>!

}

// 기본 함수 and 셋팅
extension SampleSectionTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        registCell()
        initData()

        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        initDataSource()

        // Do any additional setup after loading the view.
    }

    private func initData() {
        let today = ["today0", "today1", "today2", "today3", "today4", "today5"]
        let week = ["week0", "week1", "week2", "week3", "week4", "week5"]

        let todaySection = SampleSectionItem(sectionType: SampleSectionItem.SectionType.today, items: today)
        let weekSection = SampleSectionItem(sectionType: SampleSectionItem.SectionType.week, items: week)

        let items = [todaySection, weekSection]
        self.tableViewItems.accept(items)
    }

    private func registCell() {
        let nibName = "SampleTableViewCell"
        let nib = UINib(nibName: nibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: nibName)
    }
}

// UITableViewDelegate
extension SampleSectionTableViewController: UITableViewDelegate  {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as? CoinCell
        guard cell != nil else {
            return
        }

        print("didSelectRowAt : + \\")


    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// UITableViewDataSource
extension SampleSectionTableViewController  {
    private func initDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource<SampleSectionItem> (configureCell: { [weak self] (dataSource, tableView, indexPath, element) -> UITableViewCell in

            let cell: UITableViewCell = self?.getTableViewCell(tableView, indexPath: indexPath, item: element) ?? UITableViewCell()
            return cell
        })

        self.dataSource.titleForHeaderInSection = { dataSource, index in
            return "header" + String(index)
        }

        self.dataSource.titleForFooterInSection = { dataSource, index in
            return "footer" + String(index)
        }

        self.tableViewItems
            .asObservable()
            .bind(to: tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: disposeBag)

        self.tableView.dataSource = self.dataSource
    }

    private func getTableViewCell(_ tableView: UITableView, indexPath: IndexPath, item: String) -> UITableViewCell {
        var cell: CoinCell

        let section: SampleSectionItem.SectionType = SampleSectionItem.getSctionType(indexPath.section)

        switch section {
        case .today:
            cell = tableView.dequeueReusableCell(withIdentifier: "SampleTableViewCell", for: indexPath) as! CoinCell
            break

        case .week:
            cell = tableView.dequeueReusableCell(withIdentifier: "SampleTableViewCell", for: indexPath) as! CoinCell
            break

        case .none:
            cell = tableView.dequeueReusableCell(withIdentifier: "SampleTableViewCell", for: indexPath) as! CoinCell
            break
        }

        return cell
    }
}


