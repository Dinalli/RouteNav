//
//  MapPullUpViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 03/02/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import UIKit

class MapPullUpViewController: UIViewController {

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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.6, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height - 100)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//
//    @IBAction func close(_ sender: AnyObject) {
//        UIView.animate(withDuration: 0.3, animations: {
//            let frame = self.view.frame
//            self.view.frame = CGRect(x: 0, y: self.partialView, width: frame.width, height: frame.height)
//        })
//    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        let y = self.view.frame.minY
        if ( y + translation.y >= fullView) && (y + translation.y <= partialView ) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
            
            duration = duration > 1.3 ? 1 : duration
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                } else {
                    self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
                }
                
            }, completion: nil)
        }
    }
    
    func roundViews() {
        view.layer.cornerRadius = 5
//        holdView.layer.cornerRadius = 3
//        left.layer.cornerRadius = 10
//        right.layer.cornerRadius = 10
//        left.layer.borderColor = UIColor(colorLiteralRed: 0, green: 148/255, blue: 247.0/255.0, alpha: 1).cgColor
//        left.layer.borderWidth = 1
        view.clipsToBounds = true
    }
    
    func prepareBackgroundView(){
//        let blurEffect = UIBlurEffect.init(style: .dark)
//        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
//        let bluredView = UIVisualEffectView.init(effect: blurEffect)
//        bluredView.contentView.addSubview(visualEffect)
//
//        visualEffect.frame = UIScreen.main.bounds
//        bluredView.frame = UIScreen.main.bounds
//
//        view.insertSubview(bluredView, at: 0)
    }
    @IBAction func segmentValueChanged(_ sender: Any) {
        if (delegate != nil) {
            delegate?.segmentValueChanged(sender)
        }
    }
    
    @IBAction func actionTapped(_ sender: Any) {
        if (delegate != nil) {
            delegate?.actionButtonTapped(sender)
        }
    }
    
    @IBAction func mapTypeChanged(_ sender: Any) {
        if (delegate != nil) {
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
