//
//  StravaAPIHelper.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 21/03/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import WebKit

class StravaAPIHelper: NSObject, WKNavigationDelegate {
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    var authorisationToken :String?
    var code: String?
    var token: String!
    var athlete: [String: Any]!
    var routes: Array<[String: Any]>!
    
    let authUrl = URL(string: "https://www.strava.com/oauth/authorize?client_id=1401&response_type=code&redirect_uri=strvroute://localhost&scope=write&state=mystate&approval_prompt=force")
    
    public func exchangeCodeForToken(_ code: String, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        let tokenUrl = URL(string: "https://www.strava.com/oauth/token")
        var request = URLRequest(url: tokenUrl!)
        
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        request.timeoutInterval = 10.0
        
        let params =  ["client_id": "1401",
                       "client_secret": "967b9297f6f1c9a0a8fe10a021cf211fa35b4d59",
                       "code": code] as Dictionary<String, String>
        
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch {
            
        }
        
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResult = (try JSONSerialization.jsonObject(with: data!, options:
                            JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any]
                        
                        self.authorisationToken = jsonResult!["access_token"] as? String
                        self.athlete = jsonResult!["athlete"] as? [String: Any]
                        let athleteId = self.athlete!["id"] as? Int
                        
                        self.getRoutes(athleteId!, completionHandler: { (successFlag) in
                            return completionHandler(successFlag)
                        })
                        
                        
                    } catch {
                        //failure code
                        return completionHandler(false)
                    }
                }
                else
                {
                    return completionHandler(false)
                }
            }
        })
        dataTask?.resume()
    }
    
    public func getRoutes(_ athleteId: Int, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        let authUrl = URL(string: "https://www.strava.com/api/v3/athletes/\(athleteId)/routes")
        var request = URLRequest(url: authUrl!)
        
        request.addValue(" Bearer " + authorisationToken!, forHTTPHeaderField: "Authorization")
        request.addValue(authorisationToken!, forHTTPHeaderField: "access_token")
        
        request.httpMethod = "GET"
        
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        request.timeoutInterval = 5.0
        
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResult = (try JSONSerialization.jsonObject(with: data!, options:
                            JSONSerialization.ReadingOptions.mutableContainers))

                        self.routes = jsonResult as! Array
                        
                        //success code
                        return completionHandler(true)
                    } catch {
                        //failure code
                        print(httpResponse)
                        return completionHandler(false)
                    }
                }
                else
                {
                    
                }
            }
        })
        dataTask?.resume()
    }
    
    public func getRouteDetail(_ routeId: Int, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        
        let authUrl = URL(string: "https://www.strava.com/api/v3/routes/\(routeId)")
        var request = URLRequest(url: authUrl!)
        
        request.addValue(" Bearer " + authorisationToken!, forHTTPHeaderField: "Authorization")
        request.addValue(authorisationToken!, forHTTPHeaderField: "access_token")
        
        request.httpMethod = "GET"
        
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        request.timeoutInterval = 5.0
        
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResult = (try JSONSerialization.jsonObject(with: data!, options:
                            JSONSerialization.ReadingOptions.mutableContainers))
                        
                        self.routes = jsonResult as! Array
                        
                        //success code
                        return completionHandler(true)
                    } catch {
                        //failure code
                        print(httpResponse)
                        return completionHandler(false)
                    }
                }
                else
                {
                    
                }
            }
        })
        dataTask?.resume()
    }
}
