//
//  BarcodeScanPopover.swift
//  SimpleBuy
//
//  Created by Imran Ahmed on 09/01/2016.
//  Copyright © 2016 JOAI. All rights reserved.
//

import UIKit
protocol BarcodeReturnDelegate {
    func BarcodeDidReturnWith(name: String, EAN: String, price: String, image: UIImage);
}


class BarcodeScanPopover: UIViewController, UIPopoverPresentationControllerDelegate {
    var delegate:BarcodeReturnDelegate?
    @IBOutlet weak var navbar: UINavigationItem!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var product: UILabel!
    @IBOutlet weak var productimage: UIImageView!
    @IBOutlet weak var scanner: UIView!
    var EAN:String = "";
    var lastcode:String = "";
    var validBCode:String = "";
    var scan: MTBBarcodeScanner!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.popoverPresentationController?.delegate = self;
        self.definesPresentationContext = true;
        NSNotificationCenter.defaultCenter().removeObserver(self);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateProductName:", name: "SimpleBuy_Product_Name_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateProductImage:", name:"SimpleBuy_Product_Image_Updated", object: nil);
        navbar.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "didTapDone");
        scan = MTBBarcodeScanner(metadataObjectTypes: [AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeUPCECode], previewView: scanner);
        MTBBarcodeScanner.requestCameraPermissionWithSuccess { ( success) -> Void in
            if (!success) {
                dispatch_async(dispatch_get_main_queue() , {
                    RKDropdownAlert.title("No Camera Access - enable in settings", backgroundColor:  Utils.returnColor("Alizarin", alpha: 1.0), textColor: UIColor.whiteColor(), time: 4);
                    self.dismissViewControllerAnimated(true, completion: nil);
                });
            } else {
            
            }
        }
        scan.startScanningWithResultBlock { (codes) -> Void in
            dispatch_async(dispatch_get_main_queue() , {
                self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, 166);
                self.price.text = "";
                self.product.text = "";
                self.productimage.hidden = true;
            });
            for code in codes {
                if (code.stringValue != self.lastcode) {
                //Utils.disp(self, title: "New Code", message: code.stringValue);
                self.lastcode = code.stringValue
                    if (self.lastcode.characters.count == 13) {
                        dispatch_async(dispatch_get_main_queue() , {
                            RKDropdownAlert.title("Getting Product Information!", backgroundColor:  Utils.returnColor("Amethyst", alpha: 1.0), textColor: UIColor.whiteColor(), time: 4);
                        });
                        Utils.getProductData(self.lastcode);
                    } else {
                        dispatch_async(dispatch_get_main_queue() , {
                            RKDropdownAlert.title("Incorrect Barcode Type (EAN13 Only)", backgroundColor:  Utils.returnColor("Alizarin", alpha: 1.0), textColor: UIColor.whiteColor(), time: 4);
                        });
                    }
                } else {
                    
                }
                // Output all of the codes just scanned
            }
        }
        // Do any additional setup after loading the view.
    }
    func updateProductName(notif: NSNotification) {
        lastcode = "";
        let results = notif.userInfo as? Dictionary<String,AnyObject>;
        EAN = (results!["EANBarcode"] as! String);
        let ProdName:String = (results!["Name"] as? String)!;
        let PriceDescription:String = (results!["PriceDescription"] as? String)!;
        dispatch_async(dispatch_get_main_queue() , {
            self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, 250);
            self.productimage.hidden = false;
            self.productimage.image = UIImage(named: "unknown.png");
            self.product.text = ProdName;
            self.price.text = PriceDescription;
        });
    }
    func updateProductImage(notif: NSNotification) {
        let results = notif.userInfo as? Dictionary<String,AnyObject>;
        let data = (results!["Data"] as? NSData);
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue() , {
                self.productimage.image = UIImage(data: data!);
            });
        }
    }
    func didTapDone() {
        if (self.preferredContentSize.height == 250) {
            if let delegate = self.delegate {
                delegate.BarcodeDidReturnWith(product.text!, EAN: EAN, price: price.text!, image: productimage.image!)
            }
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func popoverPresentationControllerShouldDismissPopover(popoverController: UIPopoverPresentationController) -> Bool {
        scan.stopScanning();
        return true;
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
