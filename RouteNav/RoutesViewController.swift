//
//  RoutesViewController.swift
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

class RoutesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var routesCollectionView: UICollectionView!
    var refreshControl:UIRefreshControl!
    
    
    let apiHelper = StravaAPIHelper()
    let srtHelper = SRTHelperFunctions()
    var webView: WKWebView?
    var authVC: StravaAuthViewController?
    var selectedRoute: Route?
    var authorising: Bool = false
    var managedContext: NSManagedObjectContext!
    var routes: Array<Route> = Array<Route>()
    
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
        self.routesCollectionView.register(UINib(nibName: "RouteCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "routeCollectionCell")
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
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(refeshData), for: UIControlEvents.valueChanged)
        self.routesCollectionView!.addSubview(refreshControl)
        
        self.routesCollectionView.delegate = self
        self.routesCollectionView.dataSource = self
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
    
    @IBAction func refeshData() {
        DispatchQueue.main.async {
            self.setUpLoadingOverlay()
        }
        StravaCoreDataHandler.sharedInstance.clearCoreData()
        self.getRoutesData()
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
                    DispatchQueue.main.async {
                        self.removeLoadingOverlays()
                    }
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
                DispatchQueue.main.async {
                    self.removeLoadingOverlays()
                }
            }
        })
    }
    
    func getRouteDetails() {
        
        for route in self.routes {
            apiHelper.getRouteDetail(route) { (successFlag) in
                if !successFlag
                {
                    let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                    self.navigationItem.title = "Error loading route."
                    DispatchQueue.main.async {
                        self.removeLoadingOverlays()
                    }
                }
                else {
                    self.loadingTextLabel.text = "Getting data for \(route.routename!)"
                }
            }
        }
        self.routesCollectionView.reloadData()
        removeLoadingOverlays()
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func removeLoadingOverlays() {
        self.loadingIconImageView .removeFromSuperview()
        self.loadingTextLabel .removeFromSuperview()
        self.loadingOverlayView .removeFromSuperview()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let routeCell:RouteCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "routeCollectionCell", for: indexPath) as! RouteCollectionViewCell
        
        let route:Route = routes[indexPath.row]
        
        
        routeCell.routeNameLabel.text = route.routename
        routeCell.distanceLabel.text = "\(route.distance)"
        routeCell.elevationLabel.text = "\(route.elevation_gain)"
        routeCell.timeLabel.text = "\(route.estmovingtime)"
        
        let str = "http://maps.googleapis.com/maps/api/staticmap?sensor=false&maptype={0}&size=150x150&path=weight:3|color:red|enc:\(route.routemap?.summary_polyline! ?? "")" as String
        let encodedStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        routeCell.mapIcon.imageFromUrl(urlString: encodedStr!)

        // Configure the cell
        return routeCell
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