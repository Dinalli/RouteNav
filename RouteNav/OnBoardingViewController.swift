//
//  onBoardingViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 15/01/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import UIKit
import OnboardingKit
import MapKit

class OnBoardingViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var onboardingView: OnboardingView!
    private let model = DataModel()
    let locationManager = CLLocationManager.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        onboardingView.dataSource = model
        onboardingView.delegate = model
        locationManager.delegate = self
        model.willShow = { page in
            self.nextButton .setTitle("SKIP", for: .normal)
            if page == 3 {
                self.nextButton .setTitle("DONE", for: .normal)
            }
            if page == 2 {
                if CLLocationManager.locationServicesEnabled() {
                    self.enableLocationServices()
                }
            }
        }
    }

    func enableLocationServices() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Disable location features
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    @IBAction func nextTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
