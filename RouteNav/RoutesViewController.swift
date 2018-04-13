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

class RoutesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var routesTableView: UITableView!
    var refreshControl: UIRefreshControl!
    let backgroundImage = UIImageView()
    let apiHelper = StravaAPIHelper()
    let srtHelper = SRTHelperFunctions()
    var webView: WKWebView?
    var authVC: StravaAuthViewController?
    var selectedRoute: Route?
    var authorising: Bool = false
    var managedContext: NSManagedObjectContext!
    var routes: [Route] = [Route]()
    var loadingTextLabel = UILabel()
    var loadingOverlayView = UIView()
    var loadingIconImageView = UIImageView()
    var routeCount: Int64 = 0
    let backgroundImagesArray = [UIImage(named: "cycling-bicycle-riding-sport-38296")!,
								 UIImage(named: "pexels-photo-207779")!,
								 UIImage(named: "pexels-photo-287398")!]
    var svc: SFSafariViewController?
    var index = 0
    let animationDuration: TimeInterval = 0.5
    let switchingInterval: TimeInterval = 0.5
    override func viewDidLoad() {
        super.viewDidLoad()
        self.routesTableView.register(UINib(nibName: "RouteTableViewCell", bundle: nil), forCellReuseIdentifier: "routeTableCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.managedContext == nil {
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
        var hasRun: Bool = false
        if UserDefaults.standard .value(forKey: "hasRun") != nil {
            hasRun = (UserDefaults.standard .value(forKey: "hasRun") as? Bool)!
        }

        if hasRun == false {
            hasRun = true
            UserDefaults.standard .set(true, forKey: "hasRun")
            self.performSegue(withIdentifier: "onBoardSegue", sender: self)
        } else if authorisationToken == nil && !authorising {
            authorising = true
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleRedirectURL),
												   name: Notification.Name("SRHandleAuthRedirectURL"), object: nil)
            self.performSegue(withIdentifier: "showAuthPopover", sender: self)
        }
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(refreshData), for: UIControlEvents.valueChanged)
        self.routesTableView!.addSubview(refreshControl)
        self.routesTableView.delegate = self
        self.routesTableView.dataSource = self
    }

    func setUpLoadingOverlay() {
        addImageOverlay()
        loadingOverlayView .backgroundColor = UIColor.clear
        loadingTextLabel.frame = CGRect(x: 0, y: (self.view.frame.size.height/2),
										width: self.view.frame.size.width, height: 80)
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
                            self.loadingIconImageView.frame = CGRect(x: self.view.bounds.width+50,
																	 y: self.view.bounds.height/2,
																	 width: 50,
																	 height: 50)
                            self.view.setNeedsLayout()
                        },
                       completion: nil
        )
    }

    func addImageOverlay() {
        backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.frame = CGRect(x: 0, y: 0,
                                            width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.backgroundImage.image = UIImage(named: "pexels-photo-207779")
        self.view .addSubview(self.backgroundImage)
        startAnimatingBackgroundImages()
    }

    func removeLoadingOverlays() {
        self.loadingIconImageView .removeFromSuperview()
        self.loadingTextLabel .removeFromSuperview()
        self.loadingOverlayView .removeFromSuperview()
        self.backgroundImage .removeFromSuperview()
    }

    func startAnimatingBackgroundImages() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setCompletionBlock {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.switchingInterval) {
                self.startAnimatingBackgroundImages()
            }
        }
        let transition = CATransition()
        transition.type = kCATransitionFade
        backgroundImage.layer.add(transition, forKey: kCATransition)
        backgroundImage.image = backgroundImagesArray[index]
        CATransaction.commit()
        index = index < backgroundImagesArray.count - 1 ? index + 1 : 0
    }

    @IBAction func refreshData() {
        StravaCoreDataHandler.sharedInstance.clearCoreData()
        self.getRoutesData()
    }

    @objc func handleRedirectURL(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRHandleAuthRedirectURL"), object: nil)
        guard let url = notification.object as? NSURL else { return }
        apiHelper.code = getQueryStringParameter(url: url.absoluteString!, param: "code")
        if apiHelper.code != nil {
            self.dismiss(animated: true, completion: nil)
            apiHelper.exchangeCodeForToken(apiHelper.code!) { (successFlag) in
                if successFlag {
                    DispatchQueue.main.async {
                        self.setUpLoadingOverlay()
                        StravaCoreDataHandler.sharedInstance.clearCoreData()
                        self.getRoutesData()
                    }
                } else {
                    let alertMessage = UIAlertController(title: "No Routes",
														 message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (_) in
                        self.refreshData()
                    }))
                    self.present(alertMessage, animated: true, completion: nil)
                }
                self.authorising = false
            }
        }
    }

    func getRoutesData() {
        self.apiHelper.getRoutes(apiHelper.athleteId, completionHandler: { (successFlag) in
            if successFlag {
                if self.apiHelper.routes.count == 0 {
                    let alertMessage = UIAlertController(title: "No Routes",
														 message: "Sorry, it doesnt look like you have any routes. You can create routes on Strava to import.",
														 preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                    DispatchQueue.main.async {
                        self.removeLoadingOverlays()
                    }
                } else {
                    DispatchQueue.main.async {
                        //self.refreshControl.endRefreshing()
                        self.routes = StravaCoreDataHandler.sharedInstance.fetchRoutes()
                        self.getRouteDetails()
                    }
                }
            } else {
                let alertMessage = UIAlertController(title: "No Routes",
													 message: "Sorry, we cannot get routes as something went wrong.",
													 preferredStyle: .actionSheet)
                alertMessage.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (_) in
                    self.refreshData()
                }))
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
                if !successFlag {
                    let alertMessage = UIAlertController(title: "No Routes",
														 message: "Sorry, we cannot get routes as something went wrong.",
														 preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (_) in
                        self.refreshData()
                    }))
                    self.present(alertMessage, animated: true, completion: nil)
                    self.navigationItem.title = "Error loading route."
                    DispatchQueue.main.async {
                        self.removeLoadingOverlays()
                    }
                } else {
                    self.loadingTextLabel.text = "Getting data for \(route.routename!)"
                }
            }
        }
        self.routesTableView.reloadData()
        removeLoadingOverlays()
    }

    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailSegue" {
            guard let rnc: RouteNavigationViewController = segue.destination as? RouteNavigationViewController else { return }
            rnc.route = selectedRoute
            navigationController?.navigationBar.backItem?.title = ""
            navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false,
														 animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRoute = routes[indexPath.row]
        self.performSegue(withIdentifier: "showDetailSegue", sender: self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let routeCell: RouteTableViewCell =
            tableView.dequeueReusableCell(withIdentifier: "routeTableCell",
                                          for: indexPath) as? RouteTableViewCell else { return UITableViewCell()}
        let route: Route = routes[indexPath.row]
        routeCell.routeNameLabel.text = route.routename

        if SRTHelperFunctions.UOM == 0 {
            routeCell.distanceLabel.text = String(format: "%.02f km", arguments: [(route.distance/1000)])
        } else {
            routeCell.distanceLabel.text = String(format: "%.02f miles", arguments: [(route.distance * 0.000621371192)])
        }

        routeCell.elevationLabel.text = String(format: "%.f", route.elevation_gain) + "m"
        routeCell.timeLabel.text = srtHelper.getStringFrom(seconds: route.estmovingtime)
        let str =
            "http://maps.googleapis.com/maps/api/staticmap?sensor=false&maptype={0}&size=355x188&path=weight:3|color:red|enc:\(route.routemap?.summary_polyline! ?? "")"
                as String
        let encodedStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        routeCell.mapIcon.downloadedFrom(link: encodedStr!)
        routeCell.layer.borderColor = UIColor.gray.cgColor
        routeCell.layer.borderWidth = 1.5
        routeCell.layer.shadowOffset = CGSize(width: 5, height: 5)
        routeCell.layer.cornerRadius = 18
        routeCell.layer.shadowOpacity = 0.5
        routeCell.layer.shadowColor = UIColor.lightGray.cgColor
        return routeCell
    }
}

extension UINavigationController {
    public func presentTransparentNavigationBar() {
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.isTranslucent = true
        navigationBar.alpha = 0.2
        navigationBar.shadowImage = UIImage()
        setNavigationBarHidden(false, animated: true)
    }

    public func hideTransparentNavigationBar() {
        setNavigationBarHidden(true, animated: false)
        navigationBar.setBackgroundImage(UINavigationBar.appearance().backgroundImage(for: UIBarMetrics.default),
										 for: UIBarMetrics.default)
        navigationBar.isTranslucent = UINavigationBar.appearance().isTranslucent
        navigationBar.shadowImage = UINavigationBar.appearance().shadowImage
    }
}
