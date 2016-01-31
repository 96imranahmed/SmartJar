//
//  TableViewCell.swift
//  SimpleBuy
//
//  Created by Imran Ahmed on 09/01/2016.
//  Copyright © 2016 JOAI. All rights reserved.
//

import UIKit
class DetailCell: UITableViewCell {
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var warning: UIImageView!
    var detailDevice:Device = Device(name: "", UUID: "", date: NSDate(), mass: 0, product: "");
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func performSetup() {
        warning.hidden = detailDevice.connected;
        title.text = detailDevice.name;
        detail.text = "UUID: " + detailDevice.UUID!;
    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
