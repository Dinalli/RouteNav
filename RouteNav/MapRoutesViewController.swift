//
//  MapRoutesViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 04/12/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import CoreData
import MapKit

class MapRoutesViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    let apiHelper = StravaAPIHelper()
    let srtHelper = SRTHelperFunctions()
    var webView: WKWebView?
    var authVC: StravaAuthViewController?
    var selectedRoute: Route?
    var authorising: Bool = false
    @IBOutlet var RoutesMapView: MKMapView!
    var managedContext: NSManagedObjectContext!
    var routes: Array<Route>!
    let locationManager = CLLocationManager.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request Permission for users location
        if !CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
        RoutesMapView?.showsUserLocation = true
        RoutesMapView?.delegate = self
        startLocationUpdates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.hideTransparentNavigationBar()
        
        if(self.managedContext == nil) {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            self.managedContext = appDelegate.persistentContainer.viewContext
            
            StravaCoreDataHandler.sharedInstance.clearCoreData()
            
            self.navigationController?.presentTransparentNavigationBar()
            self.navigationItem.title = "loading routes..."
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setUpNotifications()
        if(authorisationToken == nil && !authorising)
        {
            authorising = true
            self.performSegue(withIdentifier: "showAuthPopover", sender: self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeNotifications()
    }
    
    func setUpNotifications() {
//        NotificationCenter.default.addObserver(self, selector:  #selector(self.getRouteDetails), name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(self.handleRedirectURL), name: Notification.Name("SRHandleAuthRedirectURL"), object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRHandleAuthReturnURL"), object: nil)
    }

    func handleRedirectURL(notification: NSNotification) {
        
        let url = notification.object as! NSURL
        
        apiHelper.code = getQueryStringParameter(url: url.absoluteString!, param: "code")
        
        if apiHelper.code != nil {
            
            self.dismiss(animated: true, completion: nil)
            
            apiHelper.exchangeCodeForToken(apiHelper.code!) { (successFlag) in
                if successFlag
                {
                    self.getRoutesData()
                }
                else
                {
                    let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                }
                self.authorising = false
            }
        }
    }
    
    func getRoutesData() {
        
        self.apiHelper.getRoutes(apiHelper.athleteId, completionHandler: { (successFlag) in
            if successFlag
            {
                if self.apiHelper.routes.count == 0 {
                    let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, it doesnt look like you have any routes. You can create routes on Strava to import.", preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                }
                else{
                    DispatchQueue.main.async {
                        self.routes = StravaCoreDataHandler.sharedInstance.fetchRoutes()
                        self.getRouteDetails()
                    }
                }
            }
            else
            {
                let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
            }
        })
    }
    
    func getRouteDetails() {
        
        for route in self.routes! {
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
                    }
                    
                    self.getRouteStream(route: route)
                }
            }
        }
    }
    
    func getRouteStream(route : Route) {
        
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
                
                self.addRoutesToMap(route: route)
            }
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if manager.location != nil {
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func addRoutesToMap(route: Route) {
        // Drop a pin
        let startObject = route.routeroutecoord?.firstObject as! Coordinates
        let startlocationCoord = CLLocationCoordinate2DMake(startObject.latitude, startObject.longitude)
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = startlocationCoord
        dropPin.title = route.routename
        self.RoutesMapView!.addAnnotation(dropPin)

        DispatchQueue.main.async {
            self.RoutesMapView!.showAnnotations(self.RoutesMapView!.annotations, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
}

extension UINavigationController {
    
    public func presentTransparentNavigationBar() {
        navigationBar.setBackgroundImage(UIImage(), for:UIBarMetrics.default)
        navigationBar.isTranslucent = true
        navigationBar.alpha = 0.2
        navigationBar.shadowImage = UIImage()
        setNavigationBarHidden(false, animated:true)
    }
    
    public func hideTransparentNavigationBar() {
        setNavigationBarHidden(true, animated:false)
        navigationBar.setBackgroundImage(UINavigationBar.appearance().backgroundImage(for: UIBarMetrics.default), for:UIBarMetrics.default)
        navigationBar.isTranslucent = UINavigationBar.appearance().isTranslucent
        navigationBar.shadowImage = UINavigationBar.appearance().shadowImage
    }
}
