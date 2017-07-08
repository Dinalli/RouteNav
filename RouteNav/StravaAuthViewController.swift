//
//  StravaAuthViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 08/07/2017.
//  Copyright © 2017 Andrew Donnelly. All rights reserved.
//

import UIKit
import SafariServices

class StravaAuthViewController: UIViewController {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var powerByImage: UIImageView!
    @IBOutlet weak var authButton: UIButton!
    let apiHelper = StravaAPIHelper()
    let backgroundImagesArray = [UIImage(named: "cycling-bicycle-riding-sport-38296")!,UIImage(named: "pexels-photo-207779")!,UIImage(named: "pexels-photo-287398")!]
    var svc: SFSafariViewController?
    var index = 0
    let animationDuration: TimeInterval = 0.5
    let switchingInterval: TimeInterval = 2.5
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpNotifications()
        startAnimatingBackgroundImages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        powerByImage.alpha = 0.0
        authButton.alpha = 0.0
        instructionLabel.alpha = 0.0
        instructionLabel.textColor = .gray
        backgroundImage.alpha=0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 1.0, animations: {
            self.powerByImage.alpha = 1.0
            self.authButton.alpha = 1.0
        }, completion: nil)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.powerByImage.alpha = 1.0
            self.instructionLabel.alpha = 1.0
            
        }, completion: nil)
        
        UIView.animate(withDuration: 2.0, animations: {
            self.backgroundImage.alpha = 1.0
        }, completion: nil)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func startAnimatingBackgroundImages()
    {
        CATransaction.begin()
        
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setCompletionBlock {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.switchingInterval) {
                self.startAnimatingBackgroundImages()
            }
        }
        
        let transition = CATransition()
        transition.type = kCATransitionFade
        backgroundImage.layer.add(transition, forKey: kCATransition)
        backgroundImage.image = backgroundImagesArray[index]
        
        CATransaction.commit()
        
        index = index < backgroundImagesArray.count - 1 ? index + 1 : 0
    }
    
    func setUpNotifications() {
        NotificationCenter.default.addObserver(self, selector:  #selector(self.authCompleted), name: Notification.Name("SRAuthReturnNotification"), object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SRAuthReturnNotification"), object: nil)
    }
    
    @IBAction func authenticate(_ sender: Any) {
        svc = SFSafariViewController.init(url: apiHelper.authUrl!)
        self.present(self.svc!, animated: true, completion: nil)
    }
    
    func authCompleted()
    {
        self.dismiss(animated: true, completion: nil)
        self .removeNotifications()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
