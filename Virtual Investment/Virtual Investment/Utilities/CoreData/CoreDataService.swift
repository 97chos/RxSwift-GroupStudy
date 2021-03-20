//
//  CoreDataService.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/20.
//

import Foundation
import CoreData

protocol CoreDataServiceProtocol: class {
  func fetch<T>(_:NSFetchRequest<T>) -> [T]
  func delete(_ objectID: NSManagedObjectID) -> Bool
  var context: NSManagedObjectContext? { get }
}

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

  func fetch<T>(_: NSFetchRequest<T>) -> [T] where T : NSFetchRequestResult {
    <#code#>
  }

  func delete(_ objectID: NSManagedObjectID) -> Bool {
    <#code#>
  }
}
