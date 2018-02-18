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
    
    
    public func clearCoreData() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Route")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    public func fetchRoutes() -> Array<Route> {
        
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        var fetchedRoutes:[Route]!
        
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
                print("Saving \(route.routename ?? "")")
            }
            // save the context
            do {
                try container.viewContext.save()
            } catch let error as NSError {
                // handle error
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            NotificationCenter.default.post(name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
        }
    }
    
    public func addRouteDetail(route: Route, routesDetailArray: Dictionary<String, AnyObject>!, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        
        container.viewContext.performAndWait {
            
            let directionentity =
                NSEntityDescription.entity(forEntityName: "Direction",
                                           in: container.viewContext)!
            
            let segmententity =
                NSEntityDescription.entity(forEntityName: "Segment",
                                           in: container.viewContext)!
            // add direction data
            let directionArray = routesDetailArray["directions"] as? Array<[String: Any]>
            
            if(directionArray != nil)
            {
                for directionDetail:[String: Any] in directionArray! {
                    let direction = NSManagedObject(entity: directionentity, insertInto: container.viewContext) as! Direction
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
                    let segment = NSManagedObject(entity: segmententity, insertInto: container.viewContext) as! Segment
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
            
            do {
                try container.viewContext.save()
            } catch let error as NSError {
                // handle error
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            completionHandler(true)
        }
    }
    
    public func addCoordinatesToRoute(route: Route, coordinatesArray : Array<Array<Any>>!, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        
        //container.viewContext.performAndWait {
            print("adding coordinates to route \(coordinatesArray.count)")
            
            for coordObjectIndex in 0...coordinatesArray.count-1 {
                
                let coords =
                    NSEntityDescription.entity(forEntityName: "Coordinates",
                                               in: container.viewContext)!
                
                let coordinateObject = NSManagedObject(entity: coords,
                                                       insertInto: container.viewContext) as! Coordinates
                
                coordinateObject.setValue(coordinatesArray[coordObjectIndex][0], forKeyPath: "latitude")
                coordinateObject.setValue(coordinatesArray[coordObjectIndex][1], forKeyPath: "longitude")
                route.addToRouteroutecoord(coordinateObject)
                print("adding \(coordObjectIndex)")
            }
        
        do {
            print("saving to core data")
            try container.viewContext.save()
        } catch let error as NSError {
            // handle error
            print("Could not save. \(error), \(error.userInfo)")
        }
            print("completed adding coordinates to route \(coordinatesArray.count)")
            completionHandler(true)
        //}
    }
    
    public func addCoordinatesToSegment(segment: Segment, coordinatesArray : Array<Array<Any>>!,completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        
        container.viewContext.performAndWait {
            
            for coordObjectIndex in 0...coordinatesArray.count-1 {
                
                let coords =
                    NSEntityDescription.entity(forEntityName: "SegmentCoordinates",
                                               in: container.viewContext)!
                
                let coordinateObject = NSManagedObject(entity: coords,
                                                       insertInto: container.viewContext) as! SegmentCoordinates
                
                coordinateObject.setValue(coordinatesArray[coordObjectIndex][0], forKeyPath: "latitude")
                coordinateObject.setValue(coordinatesArray[coordObjectIndex][1], forKeyPath: "longitude")
                segment.addToSegmentCoord(coordinateObject)
            }
            
            do {
                try container.viewContext.save()
            } catch let error as NSError {
                // handle error
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
        completionHandler(true)
    }
}
