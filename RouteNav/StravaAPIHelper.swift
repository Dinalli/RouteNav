//
//  StravaAPIHelper.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 21/03/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import WebKit
import CoreData

var authorisationToken: String?
class StravaAPIHelper: NSObject, WKNavigationDelegate {

    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    var code: String?
    var token: String!
    var athlete: [String: Any]!
    var athleteId: Int!
    var routes: [[String: Any]]!
    var routeDetail: [String: Any]!
    var segmentDetail: [String: Any]!

    let authUrl = URL(string:
		"https://www.strava.com/oauth/authorize?client_id=1401&response_type=code&redirect_uri=strvroute://localhost&scope=write&state=mystate&approval_prompt=force")

    public func exchangeCodeForToken(_ code: String, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        let tokenUrl = URL(string: "https://www.strava.com/oauth/token")
        var request = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        let params =  ["client_id": "1401",
                       "client_secret": "967b9297f6f1c9a0a8fe10a021cf211fa35b4d59",
					   "code": code] as [String: String]

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
                        authorisationToken = jsonResult!["access_token"] as? String
                        self.athlete = jsonResult!["athlete"] as? [String: Any]
                        self.athleteId = self.athlete!["id"] as? Int
                        return completionHandler(true)
                    } catch {
                        //failure code
                        return completionHandler(false)
                    }
                } else {
                    return completionHandler(false)
                }
            }
        })
        dataTask?.resume()
    }

    public func getRoutes(_ athleteId: Int, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        let authUrl = URL(string: "https://www.strava.com/api/v3/athletes/\(athleteId)/routes?page=0&per_page=100")
        var request = URLRequest(url: authUrl!)
        request.addValue(" Bearer " + authorisationToken!, forHTTPHeaderField: "Authorization")
        request.addValue(authorisationToken!, forHTTPHeaderField: "access_token")
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
						guard let jsonResult: [[String: Any]]  = (try JSONSerialization.jsonObject(with: data!, options:
							JSONSerialization.ReadingOptions.mutableContainers) as? [[String: Any]]) else { return }
						self.routes = jsonResult
                        DispatchQueue.main.async {
                            StravaCoreDataHandler.sharedInstance.addRoutes(routesArray: jsonResult)
                        }
                        //success cod
                        return completionHandler(true)
                    } catch {
                        //failure code
                        return completionHandler(false)
                    }
                } else {
                    return completionHandler(false)
                }
            }
        })
        dataTask?.resume()
    }

    public func getRouteStream(_ route: Route, managedContext: NSManagedObjectContext, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        print("stream for \(route.routename ?? "No route name")")
        let authUrl = URL(string: "https://www.strava.com/api/v3/routes/\(route.id)/streams")
        var request = URLRequest(url: authUrl!)
        request.addValue(" Bearer " + authorisationToken!, forHTTPHeaderField: "Authorization")
        request.addValue(authorisationToken!, forHTTPHeaderField: "access_token")
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
						guard let jsonResult: [[String: Any]]  = (try JSONSerialization.jsonObject(with: data!, options:
							JSONSerialization.ReadingOptions.mutableContainers) as? [[String: Any]]) else { return }

                        let routeStreamArray: [[String: Any]] = jsonResult
                        for routeDetail: [String: Any] in routeStreamArray {
                            if let streamDictionary = routeDetail as [String: Any]? {
                                let typeString = streamDictionary["type"] as? String
								guard let streamData: [Any] = streamDictionary["data"] as? [Any] else { return }
                                if typeString == "latlng" {
                                    DispatchQueue.main.async {
                                        StravaCoreDataHandler.sharedInstance.addCoordinatesToRoute(route: route,
																								   coordinatesArray: streamData,
																								   completionHandler: { (successFlag) in
                                            //success code
                                            return completionHandler(successFlag)
                                        })
                                    }
                                }
                            }
                        }
                    } catch {
                        //failure code
                        return completionHandler(false)
                    }
                } else {
                   return completionHandler(false)
                }
            }
        })
        dataTask?.resume()
    }

    public func getSegmentStream(_ segment: Segment, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {
        let authUrl = URL(string: "https://www.strava.com/api/v3/segments/\(segment.id)/streams")
        var request = URLRequest(url: authUrl!)
        request.addValue(" Bearer " + authorisationToken!, forHTTPHeaderField: "Authorization")
        request.addValue(authorisationToken!, forHTTPHeaderField: "access_token")
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
						guard let jsonResult: [[String: Any]]  = (try JSONSerialization.jsonObject(with: data!, options:
							JSONSerialization.ReadingOptions.mutableContainers) as? [[String: Any]]) else { return }
                        let segmentStreamArray: [[String: Any]] = jsonResult
                        for segmentDetail: [String: Any] in segmentStreamArray {
                            if let streamDictionary = segmentDetail as [String: AnyObject]? {
                                let typeString = streamDictionary["type"] as? String
                                guard let streamData: [Any] = streamDictionary["data"] as? [Any] else { return }
                                if typeString == "latlng" {
                                    DispatchQueue.main.async {
                                        StravaCoreDataHandler.sharedInstance.addCoordinatesToSegment(
											segment: segment,
											coordinatesArray: streamData,
											completionHandler: { (successFlag) in
                                            //success code
                                            return completionHandler(successFlag)
                                        })
                                    }
                                }
                            }
                        }
                    } catch {
                        //failure code
                        return completionHandler(false)
                    }
                } else {
                    return completionHandler(false)
                }
            }
        })
        dataTask?.resume()
    }

    public func getRouteDetail(_ route: Route, completionHandler: @escaping(_ successFlag: Bool) -> Swift.Void) {

        let authUrl = URL(string: "https://www.strava.com/api/v3/routes/\(route.id)")
        var request = URLRequest(url: authUrl!)
        request.addValue(" Bearer " + authorisationToken!, forHTTPHeaderField: "Authorization")
        request.addValue(authorisationToken!, forHTTPHeaderField: "access_token")
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
						guard let jsonResult: [String: Any]  = (try JSONSerialization.jsonObject(with: data!, options:
							JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any]) else { return }
                        DispatchQueue.main.async {
                            StravaCoreDataHandler.sharedInstance.addRouteDetail(route: route,
																				routesDetailArray: jsonResult,
																				completionHandler: { (successFlag) in
                                //success code
                                return completionHandler(successFlag)
                            })
						}
                    } catch {
                        //failure code
                        return completionHandler(false)
                    }
                } else {
                    return completionHandler(false)
                }
            }
        })
        dataTask?.resume()
    }
}
