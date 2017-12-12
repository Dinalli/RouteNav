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
    var loadingOverlay = UIImageView()
    
    let backgroundImagesArray = [UIImage(named: "cycling-bicycle-riding-sport-38296")!,UIImage(named: "pexels-photo-207779")!,UIImage(named: "pexels-photo-287398")!]
    var svc: SFSafariViewController?
    var index = 0
    let animationDuration: TimeInterval = 0.5
    let switchingInterval: TimeInterval = 2.5
    
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
            setUpLoadingOverlay()
        }
    }
    
    func setUpLoadingOverlay() {
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.contentMode = .scaleToFill
        self.view .addSubview(loadingOverlay)
        
        self.view .addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[loadingOverlay]|",
                                                                           options: NSLayoutFormatOptions.init(rawValue: 0),
                                                                           metrics: nil,
                                                                           views: ["loadingOverlay":loadingOverlay]))
        
        self.view .addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[loadingOverlay]|",
                                                                           options: NSLayoutFormatOptions.init(rawValue: 0),
                                                                           metrics: nil,
                                                                           views: ["loadingOverlay":loadingOverlay]))
        

        startAnimatingBackgroundImages()
    }
    
    func startAnimatingBackgroundImages()
    {
        CATransaction.begin()
        
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setCompletionBlock {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.switchingInterval) {
                self.startAnimatingBackgroundImages()
            }
        }
        
        let transition = CATransition()
        transition.type = kCATransitionFade
        loadingOverlay.layer.add(transition, forKey: kCATransition)
        loadingOverlay.image = backgroundImagesArray[index]
        
        CATransaction.commit()
        
        index = index < backgroundImagesArray.count - 1 ? index + 1 : 0
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeNotifications()
    }
    
    func setUpNotifications() {
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
        let dropPin = RouteAnnotation(title: route.routename!, coordinate: startlocationCoord, subtitle:String(format: "%.02f km", arguments: [(route.distance/1000)] ) + " time:" + srtHelper.getStringFrom(seconds: route.estmovingtime), route: route)
        self.RoutesMapView!.addAnnotation(dropPin)

        DispatchQueue.main.async {
            self.RoutesMapView!.showAnnotations(self.RoutesMapView!.annotations, animated: true)
        }
    }
}

extension MapRoutesViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of:MKUserLocation.self) else {
            return nil
        }
        
        let routeAnnotation = annotation as! RouteAnnotation
        
        let reuseId = "RouteAnnotationViewID"
        var view: MKMarkerAnnotationView
        // 4
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
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("SELECTED")
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("TAPPED")
        if control == view.rightCalloutAccessoryView {
            let routeAnnotation = view.annotation as! RouteAnnotation
            selectedRoute = routeAnnotation.route
            self.performSegue(withIdentifier: "showDetail", sender: self)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("REGION DID CHANGE ")
        self.loadingOverlay .removeFromSuperview()
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        print("DID FINISH RENDERING")
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let rnc:RouteNavigationViewController = segue.destination as! RouteNavigationViewController
            rnc.route = selectedRoute
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
