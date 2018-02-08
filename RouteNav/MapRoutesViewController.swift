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

class MapRoutesViewController: UIViewController, CLLocationManagerDelegate {

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
    
    var loadingTextLabel = UILabel()
    var loadingOverlayView = UIView()
    var loadingIconImageView = UIImageView()
    
    var routeCount:Int64 = 0
    
    let backgroundImagesArray = [UIImage(named: "cycling-bicycle-riding-sport-38296")!,UIImage(named: "pexels-photo-207779")!,UIImage(named: "pexels-photo-287398")!]
    
    var svc: SFSafariViewController?
    var index = 0
    let animationDuration: TimeInterval = 0.5
    let switchingInterval: TimeInterval = 2.5
        
    override func viewDidLoad() {
        super.viewDidLoad()
        RoutesMapView?.showsUserLocation = true
        RoutesMapView?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if(self.managedContext == nil) {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            self.managedContext = appDelegate.persistentContainer.viewContext
            StravaCoreDataHandler.sharedInstance.clearCoreData()
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.backgroundColor = .clear
            self.navigationController?.navigationBar.isTranslucent = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setUpNotifications()
        
        var hasRun:Bool = false
        if(UserDefaults.standard .value(forKey: "hasRun") != nil) {
            hasRun = UserDefaults.standard .value(forKey: "hasRun") as! Bool
        }
        
        if(hasRun == false) {
            hasRun = true
            UserDefaults.standard .set(true, forKey: "hasRun")
            self.performSegue(withIdentifier: "onBoardSegue", sender: self)
        }
        else if(authorisationToken == nil && !authorising) {
            authorising = true
            NotificationCenter.default.addObserver(self, selector:  #selector(self.handleRedirectURL), name: Notification.Name("SRHandleAuthRedirectURL"), object: nil)
            self.performSegue(withIdentifier: "showAuthPopover", sender: self)
        }
    }
    
    func setUpLoadingOverlay() {

        loadingOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        loadingOverlayView .backgroundColor = UIColor.black
        loadingOverlayView .alpha = 0.6
        
        loadingTextLabel.frame = CGRect(x: 0, y: (self.view.frame.size.height/2)+40, width: self.view.frame.size.width, height: 80)
        loadingTextLabel.text = "Loading your routes, please wait..."
        loadingTextLabel.textAlignment = .center
        loadingTextLabel.textColor = UIColor.white
        loadingTextLabel.numberOfLines = 0
        
        loadingIconImageView.image = UIImage(named: "bikeMapIcon")
        loadingIconImageView.frame = CGRect(x: 0, y: self.view.bounds.height/2, width: 50, height: 50)
        
        loadingOverlayView.addSubview(loadingTextLabel)
        loadingOverlayView.addSubview(loadingIconImageView)
        
        self.view .addSubview(loadingOverlayView)
        
        UIView.animate(withDuration: 2.5, delay: 0,
                       options: [.repeat, .curveEaseInOut],
                       animations: {
      
                            self.loadingIconImageView.frame = CGRect(x: self.view.bounds.width+50, y: self.view.bounds.height/2, width: 50, height: 50)
                            self.view.setNeedsLayout();
                       
                        },
                       completion: nil
        )

        self.view .addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[loadingOverlay]|",
                                                                           options: NSLayoutFormatOptions.init(rawValue: 0),
                                                                           metrics: nil,
                                                                           views: ["loadingOverlay":loadingOverlayView]))
        
        self.view .addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[loadingOverlay]|",
                                                                           options: NSLayoutFormatOptions.init(rawValue: 0),
                                                                           metrics: nil,
                                                                           views: ["loadingOverlay":loadingOverlayView]))

    }
    
    @IBAction func refeshData(_ sender: UIBarButtonItem) {
        print("REFRESHDATA")
        DispatchQueue.main.async {
            self.setUpLoadingOverlay()
            self.RoutesMapView.removeAnnotations(self.RoutesMapView.annotations)
        }
        StravaCoreDataHandler.sharedInstance.clearCoreData()
        self.getRoutesData()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeNotifications()
    }
    
    func setUpNotifications() {
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
    }

    @objc func handleRedirectURL(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRHandleAuthRedirectURL"), object: nil)
        let url = notification.object as! NSURL
        
        apiHelper.code = getQueryStringParameter(url: url.absoluteString!, param: "code")
        
        if apiHelper.code != nil {
            
            self.dismiss(animated: true, completion: nil)
            
            apiHelper.exchangeCodeForToken(apiHelper.code!) { (successFlag) in
                if successFlag
                {
                    DispatchQueue.main.async {
                        self.setUpLoadingOverlay()
                        StravaCoreDataHandler.sharedInstance.clearCoreData()
                        self.getRoutesData()
                    }
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
                    self.loadingTextLabel.text = "Getting data for \(route.routename!)"
                    self.getRouteStream(route: route)
                }
            }
        }
    }
    
    func getRouteStream(route : Route) {
        
        apiHelper.getRouteStream(route, managedContext: managedContext) { (successFlag) in
            if !successFlag
            {
                let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
                self.navigationItem.title = "Error loading route."
            }
            else {
                self.addRoutesToMap(route: route)
                self.loadingTextLabel.text = "Adding \(route.routename!) to Map"
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
    
    func enableLocationServices() {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            startLocationUpdates()
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            startLocationUpdates()
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            startLocationUpdates()
            break
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
        let dropPin = RouteAnnotation(title: route.routename!, coordinate: startlocationCoord, subtitle:String(format: "%.02f km", arguments: [(route.distance/1000)] ) + " time:" + srtHelper.getStringFrom(seconds: route.estmovingtime), route: route)
        self.RoutesMapView!.addAnnotation(dropPin)

        DispatchQueue.main.async {
            self.RoutesMapView!.showAnnotations(self.RoutesMapView!.annotations, animated: true)
        }
        
        if(routeCount == routes.count-1) {
            routeCount = 0
            removeLoadingOverlays()
        } else {
            print("Routes Count \(route.routename!) \(routeCount) - \(routes.count)")
            routeCount = routeCount + 1
        }
    }
    
    func removeLoadingOverlays() {
        self.loadingIconImageView .removeFromSuperview()
        self.loadingTextLabel .removeFromSuperview()
        self.loadingOverlayView .removeFromSuperview()
    }
}

extension MapRoutesViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of:MKUserLocation.self) else {
            return nil
        }
        
        let routeAnnotation = annotation as! RouteAnnotation
        
        let reuseId = "RouteAnnotationViewID"
        if #available(iOS 11.0, *) {
            var view: MKMarkerAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
                as? MKMarkerAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                //we are re-using a view, update its annotation reference...
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                view.calloutOffset = CGPoint(x: -15, y: 15)
                view.tintColor = UIColor.orange
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                view.canShowCallout = true
            }
            
            if routeAnnotation.route.type == 2 {
                view.glyphImage = UIImage(named: "runMapIcon.png")
            } else {
                view.glyphImage = UIImage(named: "bikeMapIcon.png")
            }
            
            return view
        } else {
            var view: MKAnnotationView
            // Fallback on earlier versions
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                //we are re-using a view, update its annotation reference...
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                view.tintColor = UIColor.orange
                view.canShowCallout = true
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            
            if routeAnnotation.route.type == 2 {
                view.image = UIImage(named: "smallrunIcon.png")
            } else {
                view.image = UIImage(named: "smallbikeIcon.png")
            }
            
            return view
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

        if control == view.rightCalloutAccessoryView {
            let routeAnnotation = view.annotation as! RouteAnnotation
            selectedRoute = routeAnnotation.route
            self.performSegue(withIdentifier: "showDetailSegue", sender: self)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        print("DID FINISH RENDERING")
        self.startLocationUpdates()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailSegue" {
            let rnc:RouteNavigationViewController = segue.destination as! RouteNavigationViewController
            rnc.route = selectedRoute
            navigationController?.navigationBar.backItem?.title = ""
            navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true)
        }
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
