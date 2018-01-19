//
//  onBoardingViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 15/01/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import UIKit
import OnboardingKit

class onBoardingViewController: UIViewController {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var onboardingView: OnboardingView!
    private let model = DataModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        onboardingView.dataSource = model
        onboardingView.delegate = model

        // Do any additional setup after loading the view.
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
