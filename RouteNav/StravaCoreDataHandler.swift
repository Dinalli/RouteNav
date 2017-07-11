//
//  StravaCoreDataHandler.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 05/05/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import CoreData

class StravaCoreDataHandler: NSObject {
    
    var routes: [NSManagedObject] = []
    
    // Remove all entries
    
    // Add all entries
    
    // Add Athlete
    
    // Add Route
    

    static let sharedInstance = StravaCoreDataHandler()

    public func addRoutes(routesArray: Array<[String: Any]>!) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        for routeDetail:[String: Any] in routesArray {
            let entity =
                NSEntityDescription.entity(forEntityName: "Route",
                                           in: managedContext)!
            
            let mapentity =
                NSEntityDescription.entity(forEntityName: "Map",
                                           in: managedContext)!
            
            let route = NSManagedObject(entity: entity,
                                        insertInto: managedContext) as! Route
            
            route.setValue(routeDetail["name"] as? String, forKeyPath: "name")
            route.setValue(routeDetail["estimated_moving_time"] as? NSNumber, forKeyPath: "estmovingtime")
            route.setValue(routeDetail["type"] as? NSNumber, forKeyPath: "type")
            route.setValue(routeDetail["distance"] as? NSNumber, forKeyPath: "distance")
            route.setValue(routeDetail["elevation_gain"] as? NSNumber, forKeyPath: "elevation_gain")
            route.setValue(routeDetail["description"] as? String, forKeyPath: "routedesc")
            
            let map = NSManagedObject(entity: mapentity, insertInto: managedContext) as! Map
            let mapData:[String: Any] = routeDetail["map"] as! Dictionary
            
            map.setValue(mapData["id"] as? NSNumber, forKeyPath: "id")
            map.setValue(mapData["resource_state"] as? NSNumber, forKeyPath: "resource_state")
            map.setValue(mapData["summary_polyline"] as? String, forKeyPath: "summary_polyline")
            
            route.routemap = map 
            
            do {
                try managedContext.save()
                routes.append(route)
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
        if(routes.count > 0)
        {
            NotificationCenter.default.post(name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
        }

    }
    
    // Add Direction
    
    // Add Segment
    
    // Save 
    
    public func saveCoreData() {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        do {
            try managedContext.save()
 
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

}
