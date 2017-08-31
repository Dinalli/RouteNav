//
//  RouteSumaryViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 21/04/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import MapKit
import Foundation

class RouteNavigationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let apiHelper = StravaAPIHelper()
    var route: Route!
    var polyOverlay: MKPolyline!
    var currentLocation: CLLocation?
    let locationManager = CLLocationManager.init()
    var polylineCoordinates: Array<CLLocationCoordinate2D>! = Array<CLLocationCoordinate2D>()
    var navigationCoordinates: Array<CLLocationCoordinate2D>! = Array<CLLocationCoordinate2D>()
    @IBOutlet weak var mapView: MKMapView?
    
    func setUpNotifications() {
        NotificationCenter.default.addObserver(self, selector:  #selector(self.addRouteToMap), name: Notification.Name("SRUpdateRoutesToMapNotification"), object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRUpdateRoutesToMapNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpNotifications()
        self.navigationController?.presentTransparentNavigationBar()
        self.navigationItem.title = "loading..."
        self.getRouteDetail()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request Permission for users location
        if !CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
        
        startLocationUpdates()
        // Do any additional setup after loading the view.
        mapView?.showsUserLocation = true
        mapView?.delegate = self
        mapView?.showsCompass = true
        mapView?.isZoomEnabled = true
        mapView?.showsScale = true
        
        //mapView?.mapType = .hybrid
        mapView?.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
//        mapView?.camera.pitch = 85.0
//        mapView?.camera.altitude = 223.0
//        mapView?.setCamera(mapView!.camera, animated: true)
        
        for routeDirection in route.routedirection! {
            let routeDirectionObject = routeDirection as! Direction
            print("direction name \(routeDirectionObject.name!)")
        }
        
        for rotueSegment in route.routesegment! {
            let routeSegmentObject = rotueSegment as! Direction
            print("segment name \(routeSegmentObject.name!)")
        }
    }
    
    func getRouteDetail() {
        apiHelper.getRouteDetail(route) { (successFlag) in
            if !successFlag
            {
                let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
                self.navigationItem.title = "Error loading route."
            }
            else {
                self.navigationItem.title = "drawing route on map."
            }
        }
    }
    
    func startLocationUpdates() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        
        if (CLLocationManager .headingAvailable())
        {
            locationManager.headingFilter = kCLHeadingFilterNone
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            // If status has not yet been determied, ask for authorization
            manager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            // If authorized when in use
            startLocationUpdates()
            break
        case .authorizedAlways:
            // If always authorized
            startLocationUpdates()
            break
        case .restricted:
            // If restricted by e.g. parental controls. User can't enable Location Services
            break
        case .denied:
            // If user denied your app access to Location Services, but can grant access from Settings.app
            break
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        mapView!.camera.heading = newHeading.magneticHeading
//        mapView!.camera.pitch = 85.0
//        mapView!.camera.altitude = 223.0
//        mapView!.setCamera(mapView!.camera, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last }
        
//        // Zoom to user location
//        if let userLocation = locations.last {
//            let viewRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1250, 1250)
//            mapView!.setRegion(viewRegion, animated: true)
//        }
        updateDirections(currentLocation: locations.last!)
    }
    
    func updateDirections(currentLocation: CLLocation) {
        
        if(self.navigationCoordinates.count > 0)
        {
            let nextNavigationLocation = CLLocation.init(latitude: (self.navigationCoordinates.first?.latitude)!,
                                                         longitude: (self.navigationCoordinates.first?.longitude)!)
            let currentDistance = currentLocation.distance(from: nextNavigationLocation)
            
            if (currentDistance < 1000)
            {
                // Not much point as you are near there, so lets remove it.
                self.navigationCoordinates.removeFirst()
            }else{
            
                //self.distanceLabel.text = String(format: "%.02f km", arguments: [(currentDistance/1000)] )
//                let degrees = currentLocation.bearingDegreesTo(location: nextNavigationLocation)
//                self.directionArrowImageView.image = UIImage.init(named: "bluearrowup")
//                self.directionArrowImageView.transform =
//                    CGAffineTransform(rotationAngle: CGFloat(currentLocation.getRadiansFrom(degrees: degrees)))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did fail location manager with error \(error.localizedDescription)")
    }
 
    func addRouteToMap() {
        
        for case let coordObject as Coordinates in route.routeroutecoord! {
            let locationCoord = CLLocationCoordinate2DMake(coordObject.latitude, coordObject.longitude)
            polylineCoordinates.append(locationCoord)
        }
        
        // Drop a pin
        let startObject = route.routeroutecoord?.firstObject as! Coordinates
        let startlocationCoord = CLLocationCoordinate2DMake(startObject.latitude, startObject.longitude)
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = startlocationCoord
        dropPin.title = "start"
        self.mapView!.addAnnotation(dropPin)
        
        // Drop a pin
        let endObject = route.routeroutecoord?.firstObject as! Coordinates
        let endlocationCoord = CLLocationCoordinate2DMake(endObject.latitude, endObject.longitude)
        dropPin.coordinate = endlocationCoord
        dropPin.title = "end"
        self.mapView!.addAnnotation(dropPin)
        
        navigationCoordinates = polylineCoordinates
        
        polyOverlay = MKPolyline.init(coordinates: self.polylineCoordinates, count: self.polylineCoordinates.count)
        
        DispatchQueue.main.async {
        //self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)
            self.mapView!.add(self.polyOverlay, level: .aboveLabels)
            self.navigationItem.title = self.route.name
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRender: MKPolylineRenderer = MKPolylineRenderer(polyline: self.polyOverlay)
        polylineRender.lineWidth = 7.0
        polylineRender.strokeColor = UIColor.blue
        return polylineRender
    }
}

func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    if (annotation is MKUserLocation) {
        //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
        //return nil so map draws default view for it (eg. blue dot)...
        return nil
    }
    
    let reuseId = "test"
    
    let anView = mapView.dequeueReusableAnnotationView(withIdentifier:reuseId)
    if anView == nil {
        let anView:MKAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        anView.image = UIImage(named:"xaxas")
        anView.canShowCallout = true
    }
    else {
        //we are re-using a view, update its annotation reference...
        anView?.annotation = annotation
    }
    
    return anView
}

extension CLLocation {
    
    
    func getRadiansFrom(degrees: Double ) -> Double {
        return degrees * .pi / 180
    }
    
    func getDegreesFrom(radians: Double) -> Double {
        return radians * 180 / .pi
    }
    
    
    func bearingRadianTo(location: CLLocation) -> Double {
        
        let lat1 = self.getRadiansFrom(degrees: self.coordinate.latitude)
        let lon1 = self.getRadiansFrom(degrees: self.coordinate.longitude)
        
        let lat2 = self.getRadiansFrom(degrees: location.coordinate.latitude)
        let lon2 = self.getRadiansFrom(degrees: location.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        var radiansBearing = atan2(y, x)
        
        if radiansBearing < 0.0 {
            radiansBearing += 2 * .pi
        }
        return radiansBearing
    }
    
    func bearingDegreesTo(location: CLLocation) -> Double {
        return self.getDegreesFrom(radians: self.bearingRadianTo(location: location))
    }
}


