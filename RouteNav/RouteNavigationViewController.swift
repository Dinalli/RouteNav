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
import CoreData

class RouteNavigationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var routeTimeLabel: UILabel!
    @IBOutlet weak var routeDistanceLabel: UILabel!
    @IBOutlet weak var ShadeView: UIView!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var instructionLabel: UILabel!
    
    let apiHelper = StravaAPIHelper()
    var route: Route!
    var routePolyline: RoutePolyline!
    var segmentPolyline: MKPolyline!
    var currentLocation: CLLocation?

    let locationManager = CLLocationManager.init()
    var polylineCoordinates: Array<CLLocationCoordinate2D>! = Array<CLLocationCoordinate2D>()
    var navigationCoordinates: Array<CLLocationCoordinate2D>! = Array<CLLocationCoordinate2D>()
    @IBOutlet weak var mapView: MKMapView?
    var tracking: Bool = false
    var polylinePosistion: Int!
    var managedContext: NSManagedObjectContext!
    
    let distance: CLLocationDistance = 650
    let pitch: CGFloat = 85
    let heading = 0.0
    var camera: MKMapCamera?
    
    var timer = Timer()
    var startTime = TimeInterval()
    
    var travelledDistance: Double!
    
    //MARK : ViewController Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
        
        if(self.managedContext == nil) {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            self.managedContext = appDelegate.persistentContainer.viewContext
        }
        
        self.ShadeView.layer.cornerRadius = 7.0
        
        if (self.route.routesegment?.count == 0) {
            self.getRouteDetail()
        } else {
            self.addRouteToMap()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request Permission for users location
        if !CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
        mapView?.mapType = .standard
        mapView?.showsUserLocation = true
        mapView?.delegate = self
        mapView?.showsCompass = true
        mapView?.isZoomEnabled = true
        mapView?.showsScale = true
        mapView?.showsBuildings = true
        mapView?.showsPointsOfInterest = true
        //mapView?.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
        
        let startObject = route.routeroutecoord?.firstObject as! Coordinates
        let startlocationCoord = CLLocationCoordinate2DMake(startObject.latitude, startObject.longitude)
        
        self.camera = MKMapCamera(lookingAtCenter: startlocationCoord,
                                  fromDistance: distance,
                                  pitch: pitch,
                                  heading: heading)
        mapView?.camera = self.camera!
        polylinePosistion = 0
    }
    
    //MARK : Get Data
    
    func getRouteStream() {
        
        DispatchQueue.main.async {
            self.navigationItem.title = "obtaining route steams"
        }
        
        apiHelper.getRouteStream(route, managedContext: managedContext) { (successFlag) in
            if !successFlag
            {
                let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
                self.navigationItem.title = "Error loading route."
            }
            else {
                DispatchQueue.main.async {
                    self.navigationItem.title = "got route streams"
                }

                self.getSegmentStreams()
            }
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
                DispatchQueue.main.async {
                    self.navigationItem.title = "getting route details"
                    //self.segmentsLabel.text = "\(self.route.routesegment?.count ?? 0)"
                }
                
                for routeDirection in self.route.routedirection! {
                    let routeDirectionObject = routeDirection as! Direction
                    print("direction name \(routeDirectionObject.directionname!)")
                }
                
                self.getRouteStream()
            }
        }
    }
    
    func getSegmentStreams() {
        
        for routeSegment in self.route.routesegment! {
            let routeSegmentObject = routeSegment as! Segment
            
            self.apiHelper.getSegmentStream(routeSegmentObject) { (successFlag) in
                if !successFlag
                {
                    let alertMessage = UIAlertController(title: "No Segment", message: "Sorry, we cannot get segment as something went wrong.", preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                    self.navigationItem.title = "Error loading segment."
                }
                else {
                    DispatchQueue.main.async {
                        self.showSegmentsOnMap(segmentObject: routeSegmentObject)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.navigationItem.title = "got segment data"
            self.addRouteToMap()
        }
    }
    
    //MARK : Location methods
    
    @IBAction func trackingTapped(_ sender: Any) {
        
        if tracking {
            stopLocationUpdates()
            timer.invalidate()
            DispatchQueue.main.async {
                self.goButton.setTitle("GO", for: UIControlState.normal)
            }
            self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)
        }
        else {
            self.travelledDistance = 0
            startLocationUpdates()
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
            startTime = NSDate.timeIntervalSinceReferenceDate
            DispatchQueue.main.async {
                self.goButton.setTitle("STOP", for: UIControlState.normal)
            }
        }
        tracking = !tracking
    }
    
    func updateTimer() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate
        var elapsedTime: TimeInterval = currentTime - startTime
        let minutes = UInt8(elapsedTime / 60.0)
        elapsedTime -= (TimeInterval(minutes) * 60)
        let seconds = UInt8(elapsedTime)
        elapsedTime -= TimeInterval(seconds)
        let fraction = UInt8(elapsedTime * 100)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strFraction = String(format: "%02d", fraction)
        routeTimeLabel.text = "\(strMinutes):\(strSeconds):\(strFraction)"
    }
    
    func startLocationUpdates() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        
        if (CLLocationManager .headingAvailable())
        {
            locationManager.headingFilter = 1
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
        if manager.location != nil {
            self.camera?.heading = newHeading.magneticHeading
            self.camera?.centerCoordinate = (manager.location?.coordinate)!
            mapView?.setCamera(self.camera!, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer {
            
            if currentLocation != nil {
                self.camera?.centerCoordinate = locations.last!.coordinate
                self.camera?.heading = (currentLocation?.bearingDegreesTo(location: locations.last!))!
                mapView?.setCamera(self.camera!, animated: true)
                updateDirections(currentLocation: currentLocation!)
                
                self.travelledDistance = self.travelledDistance + round( (locations.last?.distance(from: currentLocation!))!) as Double
                
                DispatchQueue.main.async {
                    self.routeDistanceLabel.text = "\(self.travelledDistance! / 1000) km"
                }
            }
            currentLocation = locations.last
        }
    }
    
    func updateDirections(currentLocation: CLLocation) {
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: getClosestLocation(location: currentLocation, locationsCordinates: navigationCoordinates)!))
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: {(response, error) in
            
            if error != nil {
                print("Error getting directions")
            } else {
                for route in (response?.routes)! {
                    for step in route.steps {
                        if( step.instructions != "Arrive at the destination" && step.instructions != "The destination is on your left" && step.instructions != "The destination is on your right") {
                            print("\(step.instructions)")
                            DispatchQueue.main.async {
                                self.instructionLabel.text = step.instructions
                            }
                        }
                    }
                }
            }
        })
        
        polylinePosistion = polylinePosistion + 1
        if(polylinePosistion == route.routeroutecoord?.count) {
            polylinePosistion = 0
        }
    }
    
    private func getClosestLocation(location: CLLocation, locationsCordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        var closestLocation: (distance: Double, coordinates: CLLocationCoordinate2D)?
        
        for loc in locationsCordinates {
            let locCoord = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            let distance = round(location.distance(from: locCoord)) as Double
            if closestLocation == nil {
                closestLocation = (distance, loc)
            } else {
                if distance < closestLocation!.distance {
                    closestLocation = (distance, loc)
                }
            }
        }
        return closestLocation?.coordinates
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
        let endObject = route.routeroutecoord?.lastObject as! Coordinates
        let endlocationCoord = CLLocationCoordinate2DMake(endObject.latitude, endObject.longitude)
        dropPin.coordinate = endlocationCoord
        dropPin.title = "end"
        self.mapView!.addAnnotation(dropPin)
        
        navigationCoordinates = polylineCoordinates
        
        routePolyline = RoutePolyline.init(coordinates: self.polylineCoordinates, count: self.polylineCoordinates.count)
        
        DispatchQueue.main.async {
            self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)
            self.mapView!.add(self.routePolyline, level: .aboveLabels)
            self.navigationItem.title = self.route.routename
        }
    }
    
    func showSegmentsOnMap(segmentObject :Segment) {
        
        // Drop a pin
        let startObject = segmentObject.segmentCoord?.firstObject as! SegmentCoordinates
        let startlocationCoord = CLLocationCoordinate2DMake(startObject.latitude, startObject.longitude)
        let startDropPin = MKPointAnnotation()
        startDropPin.coordinate = startlocationCoord
        startDropPin.title = "\(segmentObject.segmentname ?? "segment") start"
        self.mapView!.addAnnotation(startDropPin)
        
        // Drop a pin
        let endObject = segmentObject.segmentCoord?.lastObject as! SegmentCoordinates
        let endlocationCoord = CLLocationCoordinate2DMake(endObject.latitude, endObject.longitude)
        let endDropPin = MKPointAnnotation()
        endDropPin.coordinate = endlocationCoord
        endDropPin.title = "\(segmentObject.segmentname ?? "segment") end"
        self.mapView!.addAnnotation(endDropPin)
        
        var segmentCoordinatesArray: Array<CLLocationCoordinate2D>! = Array<CLLocationCoordinate2D>()
        for case let coordObject as SegmentCoordinates in segmentObject.segmentCoord! {
            let locationCoord = CLLocationCoordinate2DMake(coordObject.latitude, coordObject.longitude)
            segmentCoordinatesArray.append(locationCoord)
        }
        
        segmentPolyline = MKPolyline.init(coordinates: segmentCoordinatesArray, count: segmentCoordinatesArray.count)
        segmentPolyline.title = segmentObject.segmentname
        
        DispatchQueue.main.async {
            self.mapView!.add(self.segmentPolyline, level: .aboveLabels)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is RoutePolyline {
            let polylineRender: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRender.lineWidth = 2.0
            polylineRender.strokeColor = UIColor.blue
            return polylineRender
        } else {
            let polylineRender: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRender.lineWidth = 4.0
            polylineRender.strokeColor = UIColor.orange
            return polylineRender
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
            //return nil so map draws default view for it (eg. blue dot)...
            let anView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
            anView.glyphImage = UIImage(named: "bikeMapIcon.png")
            return anView
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


