//
//  RouteAnnotation.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 08/12/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import MapKit

class RouteAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    let subtitle: String?
    let route: Route
    
    init(title: String, coordinate: CLLocationCoordinate2D, subtitle: String, route: Route) {

        self.title = title
        self.coordinate = coordinate
        self.subtitle = subtitle
        self.route = route
        
        super.init()
    }
}
