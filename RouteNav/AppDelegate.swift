//
//  AppDelegate.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 02/02/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
//    var loader: OAuth2DataLoader?
//    let oauth2 = OAuth2CodeGrant(settings: [
//        "client_id": "1401",
//        "client_secret": "967b9297f6f1c9a0a8fe10a021cf211fa35b4d59",
//        "authorize_uri": "https://www.strava.com/oauth/authorize",
//        "token_uri": "https://www.strava.com/oauth/token",
//        "redirect_uris": ["routeNav://localhost"],
//        "approval_prompt": "force",
//        "scope": "write",
//        "keychain": false,         // if you DON'T want keychain integration
//        "response_type" : "code",
//        ] as OAuth2JSON)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        oauth2.authConfig.authorizeEmbedded = false
//        oauth2.logger = OAuth2DebugLogger(.trace)
//
//        oauth2.authParameters = ["client_id": "1401",
//                                 "client_secret": "967b9297f6f1c9a0a8fe10a021cf211fa35b4d59", "authorize_uri": "https://www.strava.com/oauth/authorize"]
//        oauth2.authorize() { authParameters, error in
//            if let params = authParameters {
//                print("Authorized! Access token is in `oauth2.accessToken`")
//                print("Authorized! Additional parameters: \(params)")
//            }
//            else {
//                print("Authorization was cancelled or went wrong: \(error)")   // error will not be nil
//            }
//        }
        
//        oauth2.authParameters = ["client_id": "1401",
//                                 "client_secret": "967b9297f6f1c9a0a8fe10a021cf211fa35b4d59"]
//        
//        if oauth2.isAuthorizing {
//            oauth2.abortAuthorization()
//        }
//        
//        oauth2.authConfig.authorizeEmbedded = true
//        oauth2.authConfig.authorizeContext = self
//        let loader = OAuth2DataLoader(oauth2: oauth2)
//        self.loader = loader
//        
//        loader.perform(request: userDataRequest) { response in
//            do {
//                let json = try response.responseJSON()
//                //self.didGetUserdata(dict: json, loader: loader)
//            }
//            catch let error {
//                print("Authorization went wrong: \(error)")
//            }
//        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "RouteNav")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        // you should probably first check if this is the callback being opened
        
        if "routenav" == url.scheme {
            if let vc = self.window?.rootViewController?.childViewControllers.first as? MyRoutesTableViewController {
                vc.handleRedirectURL(url)
                return true
            }
        }

        return true
    }

}

extension UINavigationController {
    var rootViewController : UIViewController? {
        return self.viewControllers.first
    }
}

