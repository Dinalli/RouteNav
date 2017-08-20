//
//  RouteSumaryViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 21/04/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import MapKit

class RouteNavigationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let apiHelper = StravaAPIHelper()
    var route: Route!
    var polyOverlay: MKPolyline!
    var currentLocation: CLLocation?
    let locationManager = CLLocationManager.init()
    var polylineCoordinates: Array<CLLocationCoordinate2D>! = Array<CLLocationCoordinate2D>()
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
        
        for routeDirection in route.routedirection! {
            let routeDirectionObject = routeDirection as! Direction
            print("direction name \(routeDirectionObject.name!)")
        }
        
        for rotueSegment in route.routesegment! {
            let routeSegmentObject = rotueSegment as! Direction
            print("segment name \(routeSegmentObject.name!)")
        }
        
        self.getRouteDetail()
    }
    
    func getRouteDetail() {
        apiHelper.getRouteDetail(route) { (successFlag) in
            if !successFlag
            {
                let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
            }
        }
    }
    
    func startLocationUpdates() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
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
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last }
        
        if currentLocation == nil {
            // Zoom to user location
            if let userLocation = locations.last {
                let viewRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2000, 2000)
                mapView!.setRegion(viewRegion, animated: false)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did fail location manager with error \(error.localizedDescription)")
    }
    
    
    func addRouteToMap() {
        
        for case let coordObject as Coordinates in route.routeroutecoord! {
            
            let locationCoord = CLLocationCoordinate2DMake(coordObject.latitude, coordObject.longitude)
            // Drop a pin
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = locationCoord
            dropPin.title = route.name
            self.mapView!.addAnnotation(dropPin)
            polylineCoordinates.append(locationCoord)
        }
        
        polyOverlay = MKPolyline.init(coordinates: self.polylineCoordinates, count: self.polylineCoordinates.count)
        
        DispatchQueue.main.async {
            self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)
            self.mapView!.add(self.polyOverlay, level: .aboveLabels)
        }
    }
    
    
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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


