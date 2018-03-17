//
//  CLLocationExtension.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 17/03/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import UIKit
import CoreLocation

extension CLLocation {
	func getRadiansFrom(degrees: Double ) -> Double {
		return degrees * .pi / 180
	}

	func getDegreesFrom(radians: Double) -> Double {
		return radians * 180 / .pi
	}

	func bearingRadianTo(location: CLLocation) -> Double {
		let lat1 = self.getRadiansFrom(degrees: self.coordinate.latitude)
		let lon1 = self.getRadiansFrom(degrees: self.coordinate.longitude)
		let lat2 = self.getRadiansFrom(degrees: location.coordinate.latitude)
		let lon2 = self.getRadiansFrom(degrees: location.coordinate.longitude)
		let dLon = lon2 - lon1
		let y = sin(dLon) * cos(lat2)
		let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
		var radiansBearing = atan2(y, x)
		if radiansBearing < 0.0 {
			radiansBearing += 2 * .pi
		}
		return radiansBearing
	}

	func bearingDegreesTo(location: CLLocation) -> Double {
		return self.getDegreesFrom(radians: self.bearingRadianTo(location: location))
	}
}
