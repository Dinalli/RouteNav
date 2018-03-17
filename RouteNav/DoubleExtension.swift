//
//  DoubleExtension.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 17/03/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import Foundation

extension Double {
	func truncate(places: Int) -> Double {
		return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
	}
}
