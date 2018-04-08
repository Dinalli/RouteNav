//
//  MapPullUpViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 03/02/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import UIKit

class MapPullUpViewController: UIViewController {

    @IBOutlet weak var mapSegmentControl: UISegmentedControl!
    @IBOutlet weak var segementsSwitch: UISwitch!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    public weak var delegate: MapPullUpDelegate?
    var fullView: CGFloat {
        return UIScreen.main.bounds.height - 250
    }
    var partialView: CGFloat {
        return UIScreen.main.bounds.height - 100
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(MapPullUpViewController.panGesture))
        view.addGestureRecognizer(gesture)
        roundViews()

        segementsSwitch.setOn(SRTHelperFunctions.showSegments, animated: true)
        mapSegmentControl.selectedSegmentIndex = SRTHelperFunctions.mapType
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.6, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height - 100)
        })
    }

    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        let yaxis = self.view.frame.minY
        if ( yaxis + translation.y >= fullView) && (yaxis + translation.y <= partialView ) {
            self.view.frame = CGRect(x: 0, y: yaxis + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((yaxis - fullView) / -velocity.y) :
				Double((partialView - yaxis) / velocity.y )
            duration = duration > 1.3 ? 1 : duration
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width,
											 height: self.view.frame.height)
                } else {
                    self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width,
											 height: self.view.frame.height)
                }
            }, completion: nil)
        }
    }

    func roundViews() {
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
    }

    @IBAction func segmentValueChanged(_ sender: Any) {
        if delegate != nil {
            delegate?.segmentValueChanged(sender)
        }
    }

    @IBAction func actionTapped(_ sender: Any) {
        if delegate != nil {
            delegate?.actionButtonTapped(sender)
        }
    }

    @IBAction func mapTypeChanged(_ sender: Any) {
        if delegate != nil {
            delegate?.changeMapView(sender)
        }
    }

    func updateTimeLabel(_ timeText: String) {
        self.timeLabel.text = timeText
    }

    func updateDistnaceLabel(_ distanceText: String) {
        self.distanceLabel.text = distanceText
    }
}
