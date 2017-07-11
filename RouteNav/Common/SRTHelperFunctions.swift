//
//  SRTHelperFunctions.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 10/07/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit

class SRTHelperFunctions: NSObject {
    
    func getStringFrom(seconds: Int64) -> String {
        
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = (seconds % 3600) % 60
        
        return ("\(hours):\(mins):\(secs)")
    }
}

extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else { return }
                
                DispatchQueue.main.sync() {
                    self.image = UIImage(data: data)
                }
            }
            task.resume()
        }
    }
}
