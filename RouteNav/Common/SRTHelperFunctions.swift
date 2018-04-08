//
//  SRTHelperFunctions.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 10/07/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

class SRTHelperFunctions: NSObject {

    func getStringFrom(seconds: Int64) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = (seconds % 3600) % 60
        return ("\(hours):\(mins):\(secs)")
    }

    static var mapType: Int {
        if UserDefaults.standard .value(forKey: "map") != nil {
            guard let mapTypeValue: Int = UserDefaults.standard .value(forKey: "map") as? Int else {return 0}
            return mapTypeValue
        }
        return 0
    }

    static var UOM: Int {
        if UserDefaults.standard .value(forKey: "uom") != nil {
            guard let uomValue: Int = UserDefaults.standard .value(forKey: "uom") as? Int else {return 0}
            return uomValue
        }
        return 0
    }

    static var canSpeak: Bool {
        if UserDefaults.standard .value(forKey: "speech") != nil {
            guard let canSpeakValue: Bool = UserDefaults.standard .value(forKey: "speech") as? Bool else {return false}
            return canSpeakValue
        }
        return false
    }

    static var showSegments: Bool {
        if UserDefaults.standard .value(forKey: "segments") != nil {
            guard let showSegmentsValue: Bool = UserDefaults.standard .value(forKey: "segments") as? Bool else {return false}
            return showSegmentsValue
        }
        return true
    }
}

extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.sync {
                    self.image = UIImage(data: data)
                }
            }
            task.resume()
        }
    }
}
