//
//  DeviceDetail.swift
//  SimpleBuy
//
//  Created by Imran Ahmed on 09/01/2016.
//  Copyright © 2016 JOAI. All rights reserved.
//

import UIKit

class DeviceDetail: UIViewController, UIPopoverPresentationControllerDelegate, BarcodeReturnDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    @IBOutlet weak var ProductImage: UIImageView!
    @IBOutlet weak var navbar: UINavigationItem!
    @IBOutlet weak var scan: UIButton!
    @IBOutlet weak var ProductName: UILabel!
    @IBOutlet weak var ProductPrice: UILabel!
    @IBOutlet weak var ProductEAN: UILabel!
    @IBOutlet weak var ProductView: UIView!
    @IBOutlet weak var tag: UITextField!
    var curdevice:Device = Device();
    var isPopped:Bool = false;
    @IBOutlet weak var mass: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var UUID: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if (curdevice.name == "Unregistered Device") {
            navbar.title = "Add New Device"
        } else {
            navbar.title = "Edit Device Details"
        }
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy 'at' HH:mm"
        mass.text = String(format:"%f", curdevice.mass!);
        date.text = dateFormatter.stringFromDate(curdevice.dateregistered!);
        UUID.text = curdevice.UUID;
        tag.text = curdevice.name;
        ProductView.hidden = true;
        if curdevice.product == "" {
        } else {
            Utils.getProductData(curdevice.product);
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateProductName:", name: "SimpleBuy_Product_Name_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateProductImage:", name:"SimpleBuy_Product_Image_Updated", object: nil);
        tag.delegate = self;
        // Do any additional setup after loading the view.
        let recog:UIGestureRecognizer = UIGestureRecognizer(target: self, action: "tap");
        recog.delegate = self;
        self.view.addGestureRecognizer(recog);
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if !CGRectContainsPoint(tag.frame, touch.locationInView(self.view)){
            tag.resignFirstResponder();
        }
        return false;
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    func updateProductName(notif: NSNotification) {
        if !isPopped {
            let results = notif.userInfo as? Dictionary<String,AnyObject>;
            let EANBarcode:String = (results!["EANBarcode"] as! String);
            let ProdName:String = (results!["Name"] as? String)!;
            let PriceDescription:String = (results!["PriceDescription"] as? String)!;
            dispatch_async(dispatch_get_main_queue() , {
                self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, 250);
                self.ProductView.hidden = false;
                self.ProductImage.image = UIImage(named: "unknown.png");
                self.ProductName.text = ProdName;
                self.ProductEAN.text = EANBarcode;
                self.ProductPrice.text = PriceDescription;
            });
        }
    }
    func updateProductImage(notif: NSNotification) {
        if !isPopped {
            let results = notif.userInfo as? Dictionary<String,AnyObject>;
            let data = (results!["Data"] as? NSData);
            if (data != nil) {
                dispatch_async(dispatch_get_main_queue() , {
                    self.ProductImage.image = UIImage(data: data!);
                });
            }
        }
    }
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func scandidtouch(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue() , {
            RKDropdownAlert.title("Point camera at Barcode!", backgroundColor:  Utils.returnColor("Emerald", alpha: 1.0), textColor: UIColor.whiteColor(), time: 3);
        });
        isPopped = true;
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("BarcodeScanPopover") as! BarcodeScanPopover!
        let height = 166 //300
        let width = (Int(self.view.frame.size.width)-50);
        popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
        popoverVC.modalPresentationStyle = .Popover
        popoverVC.delegate = self;
        let popover = popoverVC.popoverPresentationController!
        popover.delegate = self;
        popover.sourceView  = self.view
        popover.sourceRect = self.view.frame;
        popover.permittedArrowDirections = UIPopoverArrowDirection();
        presentViewController(popoverVC, animated: true, completion: nil);
    }
    //Popover delegates
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func BarcodeDidReturnWith(name: String, EAN: String, price: String, image: UIImage) {
        dispatch_async(dispatch_get_main_queue() , {
            self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, 250);
            self.ProductView.hidden = false;
            self.ProductImage.image = image;
            self.ProductName.text = name;
            self.ProductEAN.text = EAN;
            self.ProductPrice.text = price;
            self.curdevice.product = EAN;
        });
        isPopped = false;
    }
    override func viewWillDisappear(animated: Bool) {
        curdevice.name = tag.text;
        if let index = Globals.registered_devices.indexOf({$0.UUID == curdevice.UUID}) {
            Globals.registered_devices[index] = curdevice;
        } else {
            Globals.registered_devices.append(curdevice);
        }
        super.viewWillDisappear(animated)
    }
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
