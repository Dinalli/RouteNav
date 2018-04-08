//
//  UserSettingsViewController.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 06/04/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import UIKit

class UserSettingsViewController: UIViewController {

    @IBOutlet weak var speechSwitch: UISwitch!
    @IBOutlet weak var segmentsSwitch: UISwitch!
    @IBOutlet weak var uomSegmentControl: UISegmentedControl!
    @IBOutlet weak var mapSegmentControl: UISegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Set the default values

        speechSwitch.setOn(SRTHelperFunctions.canSpeak, animated: true)
        segmentsSwitch.setOn(SRTHelperFunctions.showSegments, animated: true)
        mapSegmentControl.selectedSegmentIndex = SRTHelperFunctions.mapType
        uomSegmentControl.selectedSegmentIndex = SRTHelperFunctions.UOM
    }

    @IBAction func mapValueChanged(_ sender: Any) {
        let mapSegControl: UISegmentedControl = (sender as? UISegmentedControl)!
        UserDefaults.standard .set(mapSegControl.selectedSegmentIndex, forKey: "map")
    }
    @IBAction func unitValueChanged(_ sender: Any) {
        let uomSegControl: UISegmentedControl = (sender as? UISegmentedControl)!
        UserDefaults.standard .set(uomSegControl.selectedSegmentIndex, forKey: "uom")
    }
    @IBAction func segmentsValueChanged(_ sender: Any) {
        let segmentSwitch: UISwitch = (sender as? UISwitch)!
        UserDefaults.standard .set(segmentSwitch.isOn, forKey: "segments")
    }

    @IBAction func speechValueChanged(_ sender: Any) {
        let speechSwitch: UISwitch = (sender as? UISwitch)!
        UserDefaults.standard .set(speechSwitch.isOn, forKey: "speech")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func donePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
