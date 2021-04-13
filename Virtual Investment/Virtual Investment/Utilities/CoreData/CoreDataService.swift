//
//  CoreDataService.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/20.
//

import Foundation
import CoreData

protocol CoreDataServiceProtocol: class {
  func fetch()
  func delete(_ objectID: NSManagedObjectID) -> Bool
  func edit(_ obbejctID: NSManagedObjectID, count: Int, boughtPrice: Double) -> Bool
  var context: NSManagedObjectContext? { get }
}

let coreData = CoreDataService.shared

class CoreDataService: CoreDataServiceProtocol {

  // MARK: Properties

  static let shared = CoreDataService()
  var context: NSManagedObjectContext?

  private init(){ }


  // MARK: CoreData

  func saveContext() -> Bool {
    guard let context = self.context else { return false }
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        return false
      }
    }
    return true
  }


  // MARK: Functions

  func fetch() {
    var coinList: [CoinInfo] = []
    guard let context = self.context else { return }

    do {
      let request: NSFetchRequest<CoinInfoMO> = CoinInfoMO.fetchRequest()
      let result = try context.fetch(request)

      result.forEach{
        let price = Ticker(currentPrice: $0.price?.currentPrice ?? 0, code: $0.price?.code ?? "", highPrice: $0.price?.highPrice ?? 0, lowPrice: $0.price?.lowPrice ?? 0)
        let coinInfo = CoinInfo(koreanName: $0.koreanName ?? "",
                                englishName: $0.englishName ?? "",
                                code: $0.code ?? "",
                                totalBoughtPrice: $0.totalBoughtPrice,
                                holdingCount: Int($0.holdingCount),
                                prices: price,
                                objectID: $0.objectID)

        coinList.append(coinInfo)
      }
      AD.boughtCoins.accept(coinList)
    } catch {
      return
    }
  }

  func insert(coin: CoinInfo) -> Bool {
    guard let context = self.context else { return false }
    let object = NSEntityDescription.insertNewObject(forEntityName: CoreDataModelEntity.coinInfo, into: context) as? CoinInfoMO
    let tickerObject = NSEntityDescription.insertNewObject(forEntityName: CoreDataModelEntity.ticker, into: context) as? TickerMO

    tickerObject?.code = coin.prices?.code
    tickerObject?.currentPrice = coin.prices?.currentPrice ?? 0
    tickerObject?.highPrice = coin.prices?.highPrice ?? 0
    tickerObject?.lowPrice = coin.prices?.lowPrice ?? 0

    object?.koreanName = coin.koreanName
    object?.englishName = coin.englishName
    object?.code = coin.code
    object?.holdingCount = Int64(coin.holdingCount)
    object?.totalBoughtPrice = coin.totalBoughtPrice
    object?.price = tickerObject

    do {
      try context.save()
      return true
    } catch {
      context.rollback()
      return false
    }
  }

  func delete(_ objectID: NSManagedObjectID) -> Bool {
    guard let context = self.context else { return false }
    let object = context.object(with: objectID)
    context.delete(object)

    do {
      try context.save()
      return true
    } catch {
      context.rollback()
      return false
    }
  }

  func clear() {
    guard let context = self.context else { return }
    let request: NSFetchRequest<CoinInfoMO> = CoinInfoMO.fetchRequest()

    do {
      let result = try context.fetch(request)
      result.forEach {
        context.delete($0)
      }
      try context.save()
    } catch {
      return
    }
  }

  func edit(_ objectID: NSManagedObjectID, count: Int, boughtPrice: Double) -> Bool {
    guard let context = self.context else { return false }
    let object = context.object(with: objectID) as? CoinInfoMO

    object?.holdingCount = Int64(count)
    object?.totalBoughtPrice = boughtPrice

    do {
      try context.save()
      return true
    } catch {
      context.rollback()
      return false
    }
  }
}
