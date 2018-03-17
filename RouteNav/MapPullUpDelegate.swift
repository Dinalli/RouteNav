//
//  MapPullUpDelegate.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 03/02/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import Foundation

public protocol MapPullUpDelegate: NSObjectProtocol {
    func changeMapView(_ sender: Any)
    func actionButtonTapped(_ sender: Any)
    func segmentValueChanged(_ sender: Any)
}
