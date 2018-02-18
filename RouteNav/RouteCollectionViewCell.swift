//
//  RouteCollectionViewCell.swift
//  RouteNav
//
//  Created by Andrew Donnelly on 18/02/2018.
//  Copyright © 2018 Andrew Donnelly. All rights reserved.
//

import UIKit

class RouteCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var mapIcon: UIImageView!
    @IBOutlet weak var routeNameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var elevationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
