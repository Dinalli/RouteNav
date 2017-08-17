//
//  RouteSumaryViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 21/04/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import MapKit

class RouteNavigationViewController: UIViewController, CLLocationManagerDelegate {
    
    let apiHelper = StravaAPIHelper()
    var route: Route!
    var currentLocation: CLLocation?
    let locationManager = CLLocationManager.init()
    @IBOutlet weak var mapView: MKMapView?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.presentTransparentNavigationBar()
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
            if successFlag
            {

            }
            else
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

}
