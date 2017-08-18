//
//  MyRoutesTableViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 02/02/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class MyRoutesTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WKNavigationDelegate{

    let apiHelper = StravaAPIHelper()
    let srtHelper = SRTHelperFunctions()
    var webView: WKWebView?
    @IBOutlet weak var tableView: UITableView?
    var authVC: StravaAuthViewController?
    var selectedRoute: Route?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.hideTransparentNavigationBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView!.register(UINib(nibName: "RouteTableViewCell", bundle: nil), forCellReuseIdentifier: "RouteTableViewCell")
    }
    
    func setUpNotifications() {
        NotificationCenter.default.addObserver(self, selector:  #selector(self.updateTableForNewData), name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(self.handleRedirectURL), name: Notification.Name("SRHandleAuthRedirectURL"), object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRHandleAuthReturnURL"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        self.setUpNotifications()
        if(authorisationToken == nil)
        {
            self.performSegue(withIdentifier: "showAuthPopover", sender: self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleRedirectURL(notification: NSNotification) {
        
        let url = notification.object as! NSURL
        
        apiHelper.code = getQueryStringParameter(url: url.absoluteString!, param: "code")
        
        if apiHelper.code != nil {
            
            self.dismiss(animated: true, completion: nil)
            
            apiHelper.exchangeCodeForToken(apiHelper.code!) { (successFlag) in
                if successFlag
                {
                    DispatchQueue.main.async {
                        // update some UI
                         self.tableView!.reloadData()
                    }
                }
                else
                {
                    let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes as something went wrong.", preferredStyle: .actionSheet)
                    alertMessage.addAction(UIAlertAction(title: "Try again", style: .default, handler: nil))
                    self.present(alertMessage, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    // MARK: - Table view processing
    
    func updateTableForNewData() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
           self.tableView?.reloadData()
        }
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return StravaCoreDataHandler.sharedInstance.routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteTableViewCell", for: indexPath) as! RouteTableViewCell
        let route = StravaCoreDataHandler.sharedInstance.routes[indexPath.row] as! Route
        
        cell.routeNameLabel?.text = route.name
        cell.distanceLabel?.text = String(route.distance/100) + "km"
        cell.elevationLabel?.text = String(route.elevation_gain) + "m"
        cell.timeLabel?.text = srtHelper.getStringFrom(seconds: route.estmovingtime)
        
//        if(route.type == 1)
//        {
//            cell.mapIcon.image = UIImage(named: "bikeIcon")
//        }
//        else
//        {
//            cell.mapIcon.image = UIImage(named: "runIcon")
//        }
        let str = "http://maps.googleapis.com/maps/api/staticmap?sensor=false&maptype={0}&size=150x150&path=weight:3|color:red|enc:\(route.routemap?.summary_polyline! ?? "")" as String
        let encodedStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        cell.mapIcon.imageFromUrl(urlString: encodedStr!)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRoute = StravaCoreDataHandler.sharedInstance.routes[indexPath.row] as? Route
        self.performSegue(withIdentifier: "showSumarySegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSumarySegue" {
            let rsvc = segue.destination as! RouteNavigationViewController
            rsvc.route = selectedRoute
        }
    }
}

extension UINavigationController {
    
    public func presentTransparentNavigationBar() {
        navigationBar.setBackgroundImage(UIImage(), for:UIBarMetrics.default)
        navigationBar.isTranslucent = true
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
