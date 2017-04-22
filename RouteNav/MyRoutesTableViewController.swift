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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func authenticate(_ sender: Any) {
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
        if url?.scheme == "routenav"
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
            }
            else
            {
                
            }
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
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
