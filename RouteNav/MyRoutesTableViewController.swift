//
//  MyRoutesTableViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 02/02/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import WebKit

class MyRoutesTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WKNavigationDelegate{

    let apiHelper = StravaAPIHelper()
    var webView: WKWebView?
    var tableView: UITableView?
    
    @IBOutlet weak var authBarButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    
    func setUpNotifications() {
        NotificationCenter.default.addObserver(self, selector:  #selector(self.updateTableForNewData), name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRUpdateRoutesNotification"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if(apiHelper.authorisationToken == nil)
        {
            let authorisationHandler = { (action:UIAlertAction!) -> Void in
                self.authenticate()
            }
            let alertMessage = UIAlertController(title: "No Routes", message: "Sorry, we cannot get routes until you authorise the app with Strava. Tap the icon in the top right to start the Authorisation process.", preferredStyle: .actionSheet)
            alertMessage.addAction(UIAlertAction(title: "Authenticate", style: .default, handler: authorisationHandler))
            self.present(alertMessage, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func authenticate(_ sender: Any) {
        authenticate()
    }
    
    func authenticate() {
        let web = WKWebView()
        web.translatesAutoresizingMaskIntoConstraints = false
        web.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        web.navigationDelegate = self
        view.addSubview(web)
        
        let views = ["web": web]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[web]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[web]|", options: [], metrics: nil, views: views))
        webView = web
        web .load(URLRequest(url: apiHelper.authUrl!))
    }
    
    // MARK: - Web View Delegate
    
    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        
        let request = navigationAction.request
        let url = request.url
        if url?.scheme == "strvroute"
        {
            if UIApplication.shared .canOpenURL(url!)
            {
                UIApplication.shared .open(url!, options: [:], completionHandler: { (result) in
                })
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if "file" != webView.url?.scheme {
            showLoadingIndicator()
        }
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        hideLoadingIndicator()
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if NSURLErrorDomain == error._domain && NSURLErrorCancelled == error._code {
            return
        }
        // do we still need to intercept "WebKitErrorDomain" error 102?
        showErrorMessage(error.localizedDescription, animated: true)
    }
    
    func showErrorMessage(_ description :String, animated: Bool)
    {
        //self.nameLabel.text = description
    }
    
    func showLoadingIndicator() {
        // TODO: implement
    }
    
    func hideLoadingIndicator() {
        // TODO: implement
    }
    
    open func handleRedirectURL(_ redirect: URL) {
        
        webView?.removeFromSuperview()
        apiHelper.code = getQueryStringParameter(url: redirect.absoluteString, param: "code")
        apiHelper.exchangeCodeForToken(apiHelper.code!) { (successFlag) in
            if successFlag
            {
                self.authBarButton?.image = UIImage(named:"973-user-selected")
                DispatchQueue.main.async {
                    // update some UI
                    self.addTableView()
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
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    // MARK: - Table view processing
    
    func updateTableForNewData() {
        tableView?.reloadData()
    }
    
    func addTableView(){
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "routeCell")
        view.addSubview(tableView)
        
        let views: [String: AnyObject]  = ["tableView": tableView, "topLayoutGuide": self.topLayoutGuide]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[tableView]-|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topLayoutGuide]-[tableView]|", options: [], metrics: nil, views: views))
        tableView.reloadData()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "routeCell", for: indexPath)

        //cell.textLabel?.text = self.apiHelper.routes[indexPath.row]["name"] as? String
        
        let route = StravaCoreDataHandler.sharedInstance.routes[indexPath.row]
        cell.textLabel?.text = route.value(forKeyPath: "name") as? String

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
