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
        guard let delegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
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

    public func fetchRoutes() -> [Route]! {
		var fetchedRoutes: [Route]!
		let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
		container?.viewContext.performAndWait {
            do {
                let routeFetch = NSFetchRequest<Route>(entityName: "Route")
                routeFetch.returnsObjectsAsFaults = false
				fetchedRoutes = try container?.viewContext.fetch(routeFetch)
            } catch {
                fatalError("Failed to fetch Routes: \(error)")
            }
        }
        return fetchedRoutes
    }

    public func addRoutes(routesArray: [[String: Any]]!) {
        let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        container?.viewContext.performAndWait {
            for routeDetail: [String: Any] in routesArray {
                let routeType = routeDetail["type"] as? NSNumber
                if routeType == 1 {
                    let entity =
                        NSEntityDescription.entity(forEntityName: "Route",
												   in: (container?.viewContext)!)!
                    let mapentity =
                        NSEntityDescription.entity(forEntityName: "Map",
												   in: (container?.viewContext)!)
                    guard let route = NSManagedObject(entity: entity,
                                                      insertInto: container?.viewContext) as? Route else { return }
                    route.setValue(routeDetail["id"] as? NSNumber, forKeyPath: "id")
                    route.setValue(routeDetail["name"] as? String, forKeyPath: "routename")
                    route.setValue(routeDetail["estimated_moving_time"] as? NSNumber, forKeyPath: "estmovingtime")
                    route.setValue(routeType, forKeyPath: "type")
                    route.setValue(routeDetail["distance"] as? NSNumber, forKeyPath: "distance")
                    route.setValue(routeDetail["elevation_gain"] as? NSNumber, forKeyPath: "elevation_gain")
                    route.setValue(routeDetail["description"] as? String, forKeyPath: "routedesc")
                    guard let map = NSManagedObject(entity: mapentity!, insertInto: container?.viewContext) as? Map else { return }
                    guard let mapData: [String: Any] = routeDetail["map"] as? Dictionary else { return }
                    map.setValue(mapData["id"] as? NSNumber, forKeyPath: "id")
                    map.setValue(mapData["resource_state"] as? NSNumber, forKeyPath: "resource_state")
                    map.setValue(mapData["summary_polyline"] as? String, forKeyPath: "summary_polyline")
                    route.routemap = map
                    print("Saving \(route.routename ?? "")")
                }
            }
            do {
                try container?.viewContext.save()
            } catch let error as NSError {
                // handle error
                print("Could not save. \(error), \(error.userInfo)")
            }
            NotificationCenter.default.post(name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
        }
    }
    public func addRouteDetail(route: Route, routesDetailArray: [String: Any]!, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
		container?.viewContext.performAndWait {
            let directionentity =
                NSEntityDescription.entity(forEntityName: "Direction",
										   in: (container?.viewContext)!)!
            let segmententity =
                NSEntityDescription.entity(forEntityName: "Segment",
										   in: (container?.viewContext)!)!
            // add direction data
            let directionArray = routesDetailArray["directions"] as? [[String: Any]]
            if directionArray != nil {
                for directionDetail: [String: Any] in directionArray! {
                    guard let direction = NSManagedObject(entity: directionentity, insertInto: container?.viewContext) as? Direction else { return }
                    direction.setValue(directionDetail["action"] as? NSNumber, forKeyPath: "action")
                    direction.setValue(directionDetail["distance"] as? NSNumber, forKeyPath: "distance")
                    direction.setValue(directionDetail["name"] as? String, forKeyPath: "directionname")
                    route.addToRoutedirection(direction)
                }
            }

            // add segment data
            let segmentArray = routesDetailArray["segments"] as? [[String: Any]]
            if segmentArray != nil {
                for segmentDetail: [String: Any] in segmentArray! {
                    guard let segment = NSManagedObject(entity: segmententity, insertInto: container?.viewContext) as? Segment else { return }
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
				try container?.viewContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            completionHandler(true)
        }
    }

    public func addCoordinatesToRoute(route: Route, coordinatesArray: [Any], completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
		let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
		for coordObjectIndex in 0...coordinatesArray.count-1 {
			let coords =
				NSEntityDescription.entity(forEntityName: "Coordinates",
										   in: (container?.viewContext)!)!

			guard let coordinateObject = NSManagedObject(entity: coords,
                                                         insertInto: container?.viewContext) as? Coordinates else { return }

            guard let coordsArrayObject: [AnyObject] = coordinatesArray[coordObjectIndex] as? [AnyObject] else {
                return
            }
            coordinateObject.setValue(coordsArrayObject[0], forKeyPath: "latitude")
            coordinateObject.setValue(coordsArrayObject[1], forKeyPath: "longitude")
			route.addToRouteroutecoord(coordinateObject)
			print("adding \(coordObjectIndex)")
		}
		do {
			try container?.viewContext.save()
		} catch let error as NSError {
			// handle error
			print("Could not save. \(error), \(error.userInfo)")
		}
		completionHandler(true)
    }

    public func addCoordinatesToSegment(segment: Segment, coordinatesArray: [Any], completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        container?.viewContext.performAndWait {
            for coordObjectIndex in 0...coordinatesArray.count-1 {
                let coords =
                    NSEntityDescription.entity(forEntityName: "SegmentCoordinates",
											   in: (container?.viewContext)!)!
                guard let coordinateObject = NSManagedObject(entity: coords,
                                                             insertInto: container?.viewContext) as? SegmentCoordinates else { return }
                guard let coordsArrayObject: [AnyObject] = coordinatesArray[coordObjectIndex] as? [AnyObject] else {
                    return
                }
                coordinateObject.setValue(coordsArrayObject[0], forKeyPath: "latitude")
                coordinateObject.setValue(coordsArrayObject[1], forKeyPath: "longitude")
                segment.addToSegmentCoord(coordinateObject)
            }
            do {
				try container?.viewContext.save()
            } catch let error as NSError {
                // handle error
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        completionHandler(true)
    }
}
