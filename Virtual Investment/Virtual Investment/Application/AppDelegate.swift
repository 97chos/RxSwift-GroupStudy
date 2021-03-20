//
//  AppDelegate.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/02/23.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    CoreDataService.shared.context = self.persistentContainer.viewContext
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func applicationWillTerminate(_ application: UIApplication) {
    _ = CoreDataService.shared.saveContext()
  }


  // MARK: CoreData

  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "UserDataModel")
    container.loadPersistentStores {
      if let error = $1 as NSError? {
        fatalError("Unresolved srror \(error), \(error.userInfo)")
      }
    }
    return container
  }()


}

