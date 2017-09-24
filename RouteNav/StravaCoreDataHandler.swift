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
    
    var managedContext: NSManagedObjectContext!
    static let sharedInstance = StravaCoreDataHandler()

    
    public func fetchRoutes() -> Array<Route> {
        
        //let container = NSPersistentContainer(name: "RouteNav")
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        var fetchedRoutes:[Route]!
        
//        container.loadPersistentStores { (storeDescription, error) in
//            if let error = error {
//                fatalError("Failed to load store: \(error)")
//            }
//        }

        container.viewContext.performAndWait {
            do {
                let routeFetch = NSFetchRequest<Route>(entityName: "Route")
                routeFetch.returnsObjectsAsFaults = false
                
                fetchedRoutes = try container.viewContext.fetch(routeFetch) as [Route]
                
            } catch {
                fatalError("Failed to fetch Routes: \(error)")
            }
        }
        
        return fetchedRoutes
    }
    
    public func addRoutes(routesArray: Array<[String: Any]>!) {
        
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        
        //let container = NSPersistentContainer(name: "RouteNav")
//        container.loadPersistentStores { (storeDescription, error) in
//            if let error = error {
//                fatalError("Failed to load store: \(error)")
//            }
//        }
        
        container.viewContext.performAndWait {

            // ... do some task on the context
            for routeDetail:[String: Any] in routesArray {
                let entity =
                    NSEntityDescription.entity(forEntityName: "Route",
                                               in: container.viewContext)!
                
                let mapentity =
                    NSEntityDescription.entity(forEntityName: "Map",
                                               in: container.viewContext)!
                
                let route = NSManagedObject(entity: entity,
                                            insertInto: container.viewContext) as! Route
                
                route.setValue(routeDetail["id"] as? NSNumber, forKeyPath: "id")
                route.setValue(routeDetail["name"] as? String, forKeyPath: "routename")
                route.setValue(routeDetail["estimated_moving_time"] as? NSNumber, forKeyPath: "estmovingtime")
                route.setValue(routeDetail["type"] as? NSNumber, forKeyPath: "type")
                route.setValue(routeDetail["distance"] as? NSNumber, forKeyPath: "distance")
                route.setValue(routeDetail["elevation_gain"] as? NSNumber, forKeyPath: "elevation_gain")
                route.setValue(routeDetail["description"] as? String, forKeyPath: "routedesc")
                
                // add map data
                let map = NSManagedObject(entity: mapentity, insertInto: container.viewContext) as! Map
                let mapData:[String: Any] = routeDetail["map"] as! Dictionary
                
                map.setValue(mapData["id"] as? NSNumber, forKeyPath: "id")
                map.setValue(mapData["resource_state"] as? NSNumber, forKeyPath: "resource_state")
                map.setValue(mapData["summary_polyline"] as? String, forKeyPath: "summary_polyline")
                route.routemap = map
            }
            // save the context
            do {
                try container.viewContext.save()
            } catch let error as NSError {
                // handle error
                print("Could not save. \(error), \(error.userInfo)")
            }
            
//            if(self.routes.count > 0)
//            {
                NotificationCenter.default.post(name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
//            }
        }
    }
    
    public func addRouteDetail(route: Route, routesDetailArray: Dictionary<String, AnyObject>!, managedContext: NSManagedObjectContext, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        let directionentity =
            NSEntityDescription.entity(forEntityName: "Direction",
                                       in: managedContext)!
        
        let segmententity =
            NSEntityDescription.entity(forEntityName: "Segment",
                                       in: managedContext)!
        // add direction data
        let directionArray = routesDetailArray["directions"] as? Array<[String: Any]>

        if(directionArray != nil)
        {
            for directionDetail:[String: Any] in directionArray! {
                let direction = NSManagedObject(entity: directionentity, insertInto: managedContext) as! Direction
                direction.setValue(directionDetail["action"] as? NSNumber, forKeyPath: "action")
                direction.setValue(directionDetail["distance"] as? NSNumber, forKeyPath: "distance")
                direction.setValue(directionDetail["name"] as? String, forKeyPath: "directionname")
                route.addToRoutedirection(direction)
            }
        }

        // add segment data
        let segmentArray = routesDetailArray["segments"] as? Array<[String: Any]>

        if(segmentArray != nil)
        {
            for segmentDetail:[String: Any] in segmentArray! {
                let segment = NSManagedObject(entity: segmententity, insertInto: managedContext) as! Segment
                segment.setValue(segmentDetail["id"] as? NSNumber, forKeyPath: "id")
                segment.setValue(segmentDetail["resource_state"] as? NSNumber, forKeyPath: "resource_state")
                segment.setValue(segmentDetail["name"] as? String, forKeyPath: "segmentname")
                segment.setValue(segmentDetail["average_grade"] as? NSNumber, forKeyPath: "average_grade")
                segment.setValue(segmentDetail["distance"] as? NSNumber, forKeyPath: "distance")
                segment.setValue(segmentDetail["elevation_high"] as? NSNumber, forKeyPath: "elevation_high")
                segment.setValue(segmentDetail["elevation_low"] as? NSNumber, forKeyPath: "elevation_low")
                segment.setValue(segmentDetail["end_latitude"] as? NSNumber, forKeyPath: "end_latitude")
                segment.setValue(segmentDetail["end_longitude"] as? NSNumber, forKeyPath: "end_longitude")
                segment.setValue(segmentDetail["start_latitude"] as? NSNumber, forKeyPath: "start_latitude")
                segment.setValue(segmentDetail["start_longitude"] as? NSNumber, forKeyPath: "start_longitude")
                route.addToRoutesegment(segment)
            }
        }
        saveCoreData(managedContext: managedContext)
        completionHandler(true)
    }
    
    public func addCoordinatesToRoute(route: Route, coordinatesArray : Array<Array<Any>>!, managedContext: NSManagedObjectContext, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        for coordObjectIndex in 0...coordinatesArray.count-1 {
            
            let coords =
                NSEntityDescription.entity(forEntityName: "Coordinates",
                                           in: managedContext)!
            
            let coordinateObject = NSManagedObject(entity: coords,
                                        insertInto: managedContext) as! Coordinates
            
            coordinateObject.setValue(coordinatesArray[coordObjectIndex][0], forKeyPath: "latitude")
            coordinateObject.setValue(coordinatesArray[coordObjectIndex][1], forKeyPath: "longitude")
            route.addToRouteroutecoord(coordinateObject)
            
            saveCoreData(managedContext: managedContext)
        }
        completionHandler(true)
    }
    
    public func addCoordinatesToSegment(segment: Segment, coordinatesArray : Array<Array<Any>>!, managedContext: NSManagedObjectContext,completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        for coordObjectIndex in 0...coordinatesArray.count-1 {
            
            let coords =
                NSEntityDescription.entity(forEntityName: "SegmentCoordinates",
                                           in: managedContext)!
            
            let coordinateObject = NSManagedObject(entity: coords,
                                                   insertInto: managedContext) as! SegmentCoordinates
            
            coordinateObject.setValue(coordinatesArray[coordObjectIndex][0], forKeyPath: "latitude")
            coordinateObject.setValue(coordinatesArray[coordObjectIndex][1], forKeyPath: "longitude")

            segment.addToSegmentCoord(coordinateObject)
            saveCoreData(managedContext: managedContext)
        }
        
        completionHandler(true)
    }

    public func saveCoreData(managedContext: NSManagedObjectContext) {

        do {
            try managedContext.save()
 
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

}
