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
import AVFoundation

class RouteNavigationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, MapPullUpDelegate {
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView?
    @IBOutlet weak var directionView: UIView!
    let mapPullUpVC = MapPullUpViewController()
    let apiHelper = StravaAPIHelper()
    var route: Route!
    var routePolyline: RoutePolyline!
    var segmentPolyline: MKPolyline!
    var currentLocation: CLLocation?
    var segmentOverlays = [MKOverlay]()
    var segmentPins = [MKPointAnnotation]()
    let locationManager = CLLocationManager.init()
    var polylineCoordinates: [CLLocationCoordinate2D]! = [CLLocationCoordinate2D]()
    var navigationCoordinates: [CLLocationCoordinate2D]! = [CLLocationCoordinate2D]()
    var tracking: Bool = false
    var polylinePosistion: Int = 0
    var managedContext: NSManagedObjectContext!
    let distance: CLLocationDistance = 650
    let pitch: CGFloat = 85
    let heading = 0.0
    var camera: MKMapCamera?
    var timer = Timer()
    var startTime = TimeInterval()
    var travelledDistance: Double!
    var lastInstruction: String = ""
    let speechSythensizer: AVSpeechSynthesizer = AVSpeechSynthesizer()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        UIApplication.shared.isIdleTimerDisabled = true

        DispatchQueue.main.async {
            self.navigationItem.title = ""
            self.navigationController?.navigationBar.backItem?.title = ""
        }
        if self.managedContext == nil {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            self.managedContext = appDelegate.persistentContainer.viewContext
        }
        if self.route != nil {
            if self.route.routeroutecoord?.count == 0 {
                getRouteStream(route: self.route)
            } else {
                self.addRouteToMap()
            }
        } else {
            let alertMessage = UIAlertController(title: "Something went wrong",
												 message: "Sorry, we dont seem to have a route, tap back and try again.", preferredStyle: .actionSheet)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertMessage, animated: true, completion: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addMapPullUpView()
        DispatchQueue.main.async {
            self.navigationItem.title = ""
            self.navigationController?.navigationBar.backItem?.title = ""
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        directionView.isHidden = true
        // Request Permission for users location
        if CLLocationManager.locationServicesEnabled() {
            enableLocationServices()
        }
        mapView?.mapType = .standard
        mapView?.showsUserLocation = true
        mapView?.delegate = self
        mapView?.showsCompass = true
        mapView?.isZoomEnabled = true
        mapView?.showsScale = true
        mapView?.showsBuildings = true
        mapView?.showsPointsOfInterest = true
        mapView?.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
        polylinePosistion = 0

        switch  SRTHelperFunctions.mapType {
        case 0:
            self.mapView?.mapType = .standard
        case 1:
            self.mapView?.mapType = .hybrid
        case 2:
            self.mapView?.mapType = .satellite
        default:
            self.mapView?.mapType = .standard
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mapView?.delegate = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func addMapPullUpView() {
        mapPullUpVC.delegate = self
        self.addChildViewController(mapPullUpVC)
        self.view.addSubview(mapPullUpVC.view)
        mapPullUpVC.didMove(toParentViewController: self)
        let height = view.frame.height
        let width  = view.frame.width
        mapPullUpVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY-60, width: width, height: height)

        DispatchQueue.main.async {
            if SRTHelperFunctions.UOM == 0 {
                self.mapPullUpVC.updateDistnaceLabel("0 km")
            } else {
                self.mapPullUpVC.updateDistnaceLabel("0 miles")
            }
        }
    }

    func enableLocationServices() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Disable location features
            let alertController = UIAlertController(
                title: "Location Access Disabled",
                message:
				"In order to track your location on the Route we need this enabled., please open this app's settings and set location access to 'While In Use'.",
                preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            let openAction = UIAlertAction(title: "Open Settings", style: .default) { (_) in
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            alertController.addAction(openAction)
            self.present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }

    @objc func updateTimer() {
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
        mapPullUpVC.updateTimeLabel("\(strMinutes):\(strSeconds):\(strFraction)")
    }

    func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        if CLLocationManager .headingAvailable() {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
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
                self.travelledDistance =
					self.travelledDistance + round( (locations.last?.distance(from: currentLocation!))!) as Double
                DispatchQueue.main.async {

                    if SRTHelperFunctions.UOM == 0 {
                        var formattedDistance: Double = self.travelledDistance / 1000
                        self.mapPullUpVC.updateDistnaceLabel("\(formattedDistance.truncate(places: 2)) km")
                    } else {
                        var formattedDistance: Double = self.travelledDistance * 0.000621371192
                        self.mapPullUpVC.updateDistnaceLabel("\(formattedDistance.truncate(places: 2)) miles")
                    }
                }
            }
            currentLocation = locations.last
        }
    }

    func updateDirections(currentLocation: CLLocation) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark:
			MKPlacemark(coordinate: getClosestLocation(location: currentLocation, locationsCordinates: navigationCoordinates)!))
        request.requestsAlternateRoutes = false
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: {(response, error) in
            if error != nil {
                print("Error getting directions \(String(describing: error?.localizedDescription))")
            } else {
                for route in (response?.routes)! {
                    for step in route.steps {
                        if step.instructions != "Arrive at the destination" &&
							step.instructions != "The destination is on your left"
							&& step.instructions != "The destination is on your right" && step.instructions != self.lastInstruction {
                            DispatchQueue.main.async {
                                if SRTHelperFunctions.canSpeak {
                                    let speakDirectionsText: AVSpeechUtterance = AVSpeechUtterance(string: step.instructions)
                                    self.speechSythensizer.speak(speakDirectionsText)
                                }
                                self.instructionLabel.text = step.instructions
                                self.lastInstruction = step.instructions

                                print(step.instructions)
                            }
                        }
                    }
                }
            }
        })
        polylinePosistion += 1
        if polylinePosistion == route.routeroutecoord?.count {
            polylinePosistion = 0
        }
    }

    private func getClosestLocation(location: CLLocation, locationsCordinates: [CLLocationCoordinate2D])
		-> CLLocationCoordinate2D? {
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
        print("cordinate count \(route.routeroutecoord!.count)")
        for case let coordObject as Coordinates in route.routeroutecoord! {
            let locationCoord = CLLocationCoordinate2DMake(coordObject.latitude, coordObject.longitude)
            polylineCoordinates.append(locationCoord)
        }
		guard let startObject: Coordinates = route.routeroutecoord?.firstObject as? Coordinates else { return }
        let startlocationCoord = CLLocationCoordinate2DMake(startObject.latitude, startObject.longitude)
        self.camera = MKMapCamera(lookingAtCenter: startlocationCoord,
                                  fromDistance: distance,
                                  pitch: pitch,
                                  heading: heading)
        mapView?.camera = self.camera!
        // Drop a pin
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = startlocationCoord
        dropPin.title = "start"
        self.mapView!.addAnnotation(dropPin)
        guard let endObject: Coordinates = route.routeroutecoord?.firstObject as? Coordinates else { return }
        let endlocationCoord = CLLocationCoordinate2DMake(endObject.latitude, endObject.longitude)
        dropPin.coordinate = endlocationCoord
        dropPin.title = "end"
        self.mapView?.addAnnotation(dropPin)
        navigationCoordinates = polylineCoordinates
        routePolyline = RoutePolyline.init(coordinates: self.polylineCoordinates, count: self.polylineCoordinates.count)
        DispatchQueue.main.async {
            self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)
            self.mapView!.add(self.routePolyline, level: .aboveLabels)
        }
        for routeSegment in self.route.routesegment! {
			guard let routeSegmentObject = routeSegment as? Segment else { return }
            self.apiHelper.getSegmentStream(routeSegmentObject) { (successFlag) in
                if !successFlag {
                    let alertMessage = UIAlertController(title: "No Segment",
														 message: "Sorry, we cannot get segment as something went wrong.",
														 preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                } else {
                    if self.mapView != nil {
                        self.showSegmentsOnMap(segmentObject: routeSegmentObject)
                    }
                }
            }

            self.apiHelper.getSegmentEffortDetail(routeSegmentObject) { (successFlag) in
                if !successFlag {
                    let alertMessage = UIAlertController(title: "No Segment Efforts",
                                                         message: "Sorry, we cannot get segment as something went wrong.",
                                                         preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                } 
            }
        }
    }

    func showSegmentsOnMap(segmentObject: Segment) {
//        guard let startObject: Coordinates = route.routeroutecoord?.firstObject as? Coordinates else { return }
//        let startlocationCoord = CLLocationCoordinate2DMake(startObject.latitude, startObject.longitude)
//        let startDropPin = MKPointAnnotation()
//        startDropPin.coordinate = startlocationCoord
//        startDropPin.title = "\(segmentObject.segmentname ?? "segment") start"
//        self.mapView!.addAnnotation(startDropPin)
//        segmentPins .append(startDropPin)
//        guard let endObject: Coordinates = route.routeroutecoord?.firstObject as? Coordinates else { return }
//        let endlocationCoord = CLLocationCoordinate2DMake(endObject.latitude, endObject.longitude)
//        let endDropPin = MKPointAnnotation()
//        endDropPin.coordinate = endlocationCoord
//        endDropPin.title = "\(segmentObject.segmentname ?? "segment") end"
//        self.mapView!.addAnnotation(endDropPin)
//        segmentPins .append(endDropPin)
        var segmentCoordinatesArray: [CLLocationCoordinate2D]! = [CLLocationCoordinate2D]()
        for case let coordObject as SegmentCoordinates in segmentObject.segmentCoord! {
            let locationCoord = CLLocationCoordinate2DMake(coordObject.latitude, coordObject.longitude)
            segmentCoordinatesArray.append(locationCoord)
        }
        segmentPolyline = MKPolyline.init(coordinates: segmentCoordinatesArray, count: segmentCoordinatesArray.count)
        segmentPolyline.title = segmentObject.segmentname
        DispatchQueue.main.async {
            if SRTHelperFunctions.showSegments {
                self.mapView!.add(self.segmentPolyline, level: .aboveLabels)
            }
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
            segmentOverlays .append(overlay)
            return polylineRender
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            if #available(iOS 11.0, *) {
                let anView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                anView.glyphImage = UIImage(named: "bikeMapIcon.png")
                return anView
            } else {
                // Fallback on earlier versions
                let anView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                anView.canShowCallout = true
                anView.image = UIImage(named: "smallbikeIcon.png")
                return anView
            }
        }

        let mapAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: "mapAnnotation")
        if annotation.title == "end" {
            if #available(iOS 11.0, *) {
                let mapAnnotation = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "mapAnnotation")
                mapAnnotation.glyphImage = UIImage(named: "cheq.png")
                return mapAnnotation
            } else {
                // Fallback on earlier versions
                let mapAnnotation = MKAnnotationView(annotation: annotation, reuseIdentifier: "mapAnnotation")
                mapAnnotation.canShowCallout = true
                mapAnnotation.image = UIImage(named: "smallcheq.png")
                return mapAnnotation
            }
        } else {
            if mapAnnotation == nil {
                let mapAnnotation: MKAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "mapAnnotation")
                mapAnnotation.image = UIImage(named: "none")
                mapAnnotation.canShowCallout = true
            } else {
                mapAnnotation?.annotation = annotation
            }
        }
        return mapAnnotation
    }

    func changeMapView(_ sender: Any) {
        let mapChoiceControl: UISegmentedControl = (sender as? UISegmentedControl)!
        switch  mapChoiceControl.selectedSegmentIndex {
        case 0:
            self.mapView?.mapType = .standard
        case 1:
            self.mapView?.mapType = .hybrid
        case 2:
            self.mapView?.mapType = .satellite
        default:
            self.mapView?.mapType = .standard
        }
    }

    func actionButtonTapped(_ sender: Any) {
        let actionButton: UIButton = (sender as? UIButton)!
        if tracking {
            directionView.isHidden = true
            DispatchQueue.main.async {
                actionButton .setTitle("START", for: .normal)
            }
            stopLocationUpdates()
            timer.invalidate()
            self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)
        } else {
            directionView.isHidden = false
            self.travelledDistance = 0
            startLocationUpdates()
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self,
										 selector: #selector(self.updateTimer),
										 userInfo: nil, repeats: true)
            startTime = NSDate.timeIntervalSinceReferenceDate
            DispatchQueue.main.async {
                actionButton .setTitle("STOP", for: .normal)
            }
        }
        tracking = !tracking
    }

    func segmentValueChanged(_ sender: Any) {
        let segmentSwitch: UISwitch = (sender as? UISwitch)!
        if segmentSwitch.isOn {
            mapView?.addOverlays(segmentOverlays)
            mapView?.addAnnotations(segmentPins)
        } else {
            mapView?.removeOverlays(segmentOverlays)
            mapView?.removeAnnotations(segmentPins)
        }
    }

    func getRouteStream(route: Route) {
        apiHelper.getRouteStream(route, managedContext: managedContext) { (successFlag) in
            if !successFlag {
                let alertMessage = UIAlertController(title: "No Routes",
													 message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
                self.navigationItem.title = "Error loading route."
            } else {
                if self.mapView != nil {
                    self.addRouteToMap()
                }
            }
        }
    }

    func removeMap() {
        mapView?.delegate = nil
        mapView?.removeFromSuperview()
        mapView = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        stopLocationUpdates()
        removeMap()
    }
}
