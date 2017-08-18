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
            
            let directionentity =
                NSEntityDescription.entity(forEntityName: "Direction",
                                           in: managedContext)!
            
            let segmententity =
                NSEntityDescription.entity(forEntityName: "Segment",
                                           in: managedContext)!
            
            let route = NSManagedObject(entity: entity,
                                        insertInto: managedContext) as! Route
            
            route.setValue(routeDetail["id"] as? NSNumber, forKeyPath: "id")
            route.setValue(routeDetail["name"] as? String, forKeyPath: "name")
            route.setValue(routeDetail["estimated_moving_time"] as? NSNumber, forKeyPath: "estmovingtime")
            route.setValue(routeDetail["type"] as? NSNumber, forKeyPath: "type")
            route.setValue(routeDetail["distance"] as? NSNumber, forKeyPath: "distance")
            route.setValue(routeDetail["elevation_gain"] as? NSNumber, forKeyPath: "elevation_gain")
            route.setValue(routeDetail["description"] as? String, forKeyPath: "routedesc")
            
            // add map data
            let map = NSManagedObject(entity: mapentity, insertInto: managedContext) as! Map
            let mapData:[String: Any] = routeDetail["map"] as! Dictionary
            
            map.setValue(mapData["id"] as? NSNumber, forKeyPath: "id")
            map.setValue(mapData["resource_state"] as? NSNumber, forKeyPath: "resource_state")
            map.setValue(mapData["summary_polyline"] as? String, forKeyPath: "summary_polyline")
            route.routemap = map 
            
            // add direction data
            let directionArray = routeDetail["directions"] as? Array<[String: Any]>
            
            if(directionArray != nil)
            {
                for directionDetail:[String: Any] in directionArray! {
                    let direction = NSManagedObject(entity: directionentity, insertInto: managedContext) as! Direction
                    direction.setValue(directionDetail["action"] as? NSNumber, forKeyPath: "action")
                    direction.setValue(directionDetail["distance"] as? NSNumber, forKeyPath: "distance")
                    direction.setValue(directionDetail["name"] as? String, forKeyPath: "name")
                    route.addToRoutedirection(direction)
                }
            }
            
            // add segment data
            let segmentArray = routeDetail["segments"] as? Array<[String: Any]>
            
            if(segmentArray != nil)
            {
                for segmentDetail:[String: Any] in segmentArray! {
                    let segment = NSManagedObject(entity: segmententity, insertInto: managedContext) as! Segment
                    segment.setValue(segmentDetail["id"] as? NSNumber, forKeyPath: "id")
                    segment.setValue(segmentDetail["resource_state"] as? NSNumber, forKeyPath: "resource_state")
                    segment.setValue(segmentDetail["name"] as? String, forKeyPath: "name")
                    route.addToRoutesegment(segment)
                }
            }
            
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
    
    public func addCoordinatesToRoute(route: Route, coordinatesArray : Array<Array<Any>>!) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        for coordObjectIndex in 0...coordinatesArray.count-1 {
            
            let coords =
                NSEntityDescription.entity(forEntityName: "Coordinates",
                                           in: managedContext)!
            
            let coordinateObject = NSManagedObject(entity: coords,
                                        insertInto: managedContext) as! Coordinates
            
            coordinateObject.setValue(coordinatesArray[coordObjectIndex][0], forKeyPath: "latitude")
            coordinateObject.setValue(coordinatesArray[coordObjectIndex][1], forKeyPath: "longitude")
            route.addToRouteroutecoord(coordinateObject)
            
            do {
                try managedContext.save()
                self.routes.append(route)
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
        if(routes.count > 0)
        {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
            }
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
