//
//  Utils.swift
//  SimpleBuy
//
//  Created by Imran Ahmed on 09/01/2016.
//  Copyright © 2016 JOAI. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import SystemConfiguration

class Globalvar {
    var cur_devices:[CBPeripheral];
    var registered_devices:[Device];
    var ble_dev: BLE;
    let scan_timeout = 5.0;
    var user: User;
    var tescosessionkey: String;
    var service: GTLServiceSensor? = nil;
    init () {
        self.cur_devices = [];
        self.registered_devices = [];
        self.ble_dev = BLE();
        self.user = User(name: "Imran", userid: "0");
        self.tescosessionkey = "";
        if service == nil {
            service = GTLServiceSensor()
            service?.retryEnabled = true
        }
    }
}
class User {
    var name: String?
    var userid: String?
    init (name: String, userid: String) {
        self.name = name;
        self.userid = userid;
    }
}
class Device {
    var name: String?
    var UUID: String?
    var dateregistered: NSDate?
    var mass: Double?
    var connected: Bool;
    var product: String;
    init (name: String, UUID: String, date: NSDate, mass: Double, product: String) {
        self.name = name;
        self.UUID = UUID;
        self.dateregistered = date;
        self.mass = mass;
        self.connected = false;
        self.product = product;
    }
    init() {
        self.name = "Unregistered Device";
        self.UUID = "Unknown UUID";
        self.dateregistered = NSDate();
        self.mass = 1.0;
        self.connected = false;
        self.product = "";
    }
    init(UUID: String) {
        self.name = "Unregistered Device";
        self.UUID = UUID;
        self.dateregistered = NSDate();
        self.mass = 1.0;
        self.connected = true;
        self.product = "";
    }
}
class Utils {
    class func isConnectedToNetwork()->Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags.ConnectionAutomatic
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    //Tesco Functions
    class func getSessionKey(productID:String) {
        let url = "https://secure.techfortesco.com/tescolabsapi/restservice.aspx?command=login&email=96imranahmed@gmail.com&password=Cambridge2016!&developerkey=tuHJqK8XLK5v34E3gJnM&applicationkey=73745C20840560514A67"
        let contentBodyAsString = "";
        let request = NSMutableURLRequest(URL: NSURL(string: url)!);
        request.HTTPMethod = "GET";
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
        request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            //NSLog((NSString(data: data!, encoding: NSUTF8StringEncoding)?.description)!);
            //let subString = (response.description as NSString).containsString("Error") - Checks for error
            do {
                let results = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? Dictionary<String,AnyObject>
                if let check = results!["SessionKey"] {
                    Globals.tescosessionkey = check as! String;
                }
                if productID.characters.count == 13 {
                    getProductData(productID);
                }
            } catch {
            }
            
        }
        task.resume()
    }
    class func getProductData(EAN:String) {
        if Globals.tescosessionkey == "" {
            getSessionKey(EAN)
        } else {
            let url = "https://secure.techfortesco.com/tescolabsapi/restservice.aspx?command=PRODUCTSEARCH&searchtext=" + EAN + "&page=1&sessionkey=" + Globals.tescosessionkey;
            let contentBodyAsString = "";
            let request = NSMutableURLRequest(URL: NSURL(string: url)!);
            request.HTTPMethod = "GET";
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
            request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                (data, response, error) in
                //NSLog((NSString(data: data!, encoding: NSUTF8StringEncoding)?.description)!);
                //let subString = (response.description as NSString).containsString("Error") - Checks for error
                do {
                    let resultsa = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? Dictionary<String,AnyObject>
                    let results = (resultsa!["Products"] as! NSArray)[0] as? Dictionary<String, AnyObject>;
                    let EANBarcode:String = (results!["EANBarcode"] as! String);
                    if (EANBarcode.characters.count == 13 && EANBarcode == EAN) {
                    let ImagePath:String = (results!["ImagePath"] as? String)!;
                    NSNotificationCenter.defaultCenter().postNotificationName("SimpleBuy_Product_Name_Updated", object: self, userInfo: results);
                    let imageRequest: NSURLRequest = NSURLRequest(URL: NSURL(string: ImagePath)!);
                    let queue: NSOperationQueue = NSOperationQueue.mainQueue()
                    NSURLConnection.sendAsynchronousRequest(imageRequest, queue: queue, completionHandler:{ (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                        if data != nil {
                            var params = Dictionary<String,AnyObject>();
                            params["Data"] = data;
                            NSNotificationCenter.defaultCenter().postNotificationName("SimpleBuy_Product_Image_Updated", object: self, userInfo: params);
                        }
                    })
                    
                    } else {
                        dispatch_async(dispatch_get_main_queue() , {
                        RKDropdownAlert.title("Product not found! :'(", backgroundColor:  Utils.returnColor("Turquoise", alpha: 1.0), textColor: UIColor.whiteColor(), time: 4);
                        });
                    }
                } catch {
                    dispatch_async(dispatch_get_main_queue() , {
                    RKDropdownAlert.title("No Internet Connection :'(", backgroundColor:  Utils.returnColor("Orange", alpha: 1.0), textColor: UIColor.whiteColor(), time: 4);
                    });
                }
                
            }
            task.resume()
        }
    }
    class func getProductImage(Link: String) {
        let contentBodyAsString = "";
        let request = NSMutableURLRequest(URL: NSURL(string: Link)!);
        request.HTTPMethod = "GET";
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
        request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            //NSLog((NSString(data: data!, encoding: NSUTF8StringEncoding)?.description)!);
            //let subString = (response.description as NSString).containsString("Error") - Checks for error
            NSNotificationCenter.defaultCenter().postNotificationName("SimpleBuy_Product_Name_Update", object: self, userInfo:
                ["Data" : data!]);
        }
        task.resume()
    }
    class func postToServer(stub: String, postdata: Dictionary<String, AnyObject>, customselector: String?) -> Void {
        let URLStub: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
        //Clean Values by escaping
        var dictsend = Dictionary<String, String>()
        for (key, value) in postdata {
            if let stringArray = value as? [String] {
                for (var i=0; i<stringArray.count; i++) {
                    let newkey = (key as String) + "[" + (i.description) + "]";
                    dictsend[newkey] = Utils.escapeString(stringArray[i]);
                }
            }
            else {
                dictsend[key as String] = Utils.escapeString(value as! String);
            }
        }
        dictsend["userid"] = Globals.user.userid;
        //Convert values into string
        var contentBodyAsString = "";
        var firstOneAdded = false
        let contentKeys:Array<String> = Array(dictsend.keys)
        for contentKey in contentKeys {
            if(!firstOneAdded) {
                contentBodyAsString += contentKey + "=" + dictsend[contentKey]!
                firstOneAdded = true
            }
            else {
                contentBodyAsString += "&" + contentKey + "=" + dictsend[contentKey]!
            }
        }
        
        let urlstring = URLStub + (stub);
        let url = NSURL(string: urlstring)!;
        _ = NSURLSession.sharedSession();
        let request = NSMutableURLRequest(URL: url);
        request.HTTPMethod = "POST";
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
        request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            //NSLog((NSString(data: data!, encoding: NSUTF8StringEncoding)?.description)!);
            //let subString = (response.description as NSString).containsString("Error") - Checks for error
        }
        task.resume()
    }
    
    class func escapeString(input: String) -> String {
        var output = input;
        output = output.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!;
        //output = output.stringByReplacingOccurrencesOfString("%", withString: "%25");
        //output = output.stringByReplacingOccurrencesOfString("'", withString: "''");
        output = output.stringByReplacingOccurrencesOfString("&", withString: "%26");
        output = output.stringByReplacingOccurrencesOfString("+", withString: "%2B");
        output = output.stringByReplacingOccurrencesOfString("/", withString: "%2F");
        output = output.stringByReplacingOccurrencesOfString("?", withString: "%3F");
        output = output.stringByReplacingOccurrencesOfString("#", withString: "%23");
        return output;
    }
    static  func disp(targetVC: UIViewController, title: String, message: String){
        dispatch_async(dispatch_get_main_queue(),{
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction((UIAlertAction(title: "OK", style: .Default, handler: {(action) -> Void in
            })))
            targetVC.presentViewController(alert, animated: true, completion: nil)
        })
    }
    static func getDeviceUUIDs() -> [String] {
        var UUIDs:[String] = [];
        for (value) in Globals.cur_devices {
            UUIDs.append(value.identifier.UUIDString);
        }
        return UUIDs;
    }
    static func checkActiveUUID(identifier: String) -> Bool {
        for (value) in Globals.cur_devices {
            if (identifier == value.identifier.UUIDString) { return true };
        }
        return false;
    }
    static func verifyRegisteredDevices() {
        var replace:[Device] = [];
        for (value) in Globals.registered_devices {
            if (!Utils.checkActiveUUID(value.UUID!)) {
                value.connected = false;
            } else {
                value.connected = true;
                Globals.cur_devices = Globals.cur_devices.filter({$0.identifier.UUIDString != value.UUID});
            }
            replace.append(value);
        }
        Globals.registered_devices = replace;
    }
    static func sortDevices() {
        Globals.registered_devices.sortInPlace({$0.name < $1.name});
        Globals.cur_devices.sortInPlace({$0.identifier.UUIDString > $1.identifier.UUIDString});
    }
    class func returnColor(name: String, alpha: CGFloat) -> UIColor {
        switch name {
        case "Turquoise":
            return UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: alpha)
        case "Emerald":
            return UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: alpha)
        case "Peter River":
            return UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: alpha)
        case "Amethyst":
            return UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: alpha)
        case "Wet Asphalt":
            return UIColor(red: 52/255, green: 73/255, blue: 94/255, alpha: alpha)
        case "Green Sea":
            return UIColor(red: 22/255, green: 160/255, blue: 133/255, alpha: alpha)
        case "Nephritis":
            return UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: alpha)
        case "Belize Hole":
            return UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: alpha)
        case "Wisteria":
            return UIColor(red: 142/255, green: 68/255, blue: 173/255, alpha: alpha)
        case "Midnight Blue":
            return UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: alpha)
        case "Sunflower":
            return UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: alpha)
        case "Carrot":
            return UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: alpha)
        case "Alizarin":
            return UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: alpha)
        case "Clouds":
            return UIColor(red: 236/255, green: 240/255, blue: 241/255, alpha: alpha)
        case "Concrete":
            return UIColor(red: 149/255, green: 165/255, blue: 166/255, alpha: alpha)
        case "Orange":
            return UIColor(red: 243/255, green: 156/255, blue: 18/255, alpha: alpha)
        case "Pumpkin":
            return UIColor(red: 211/255, green: 84/255, blue: 0/255, alpha: alpha)
        case "Pomegranite":
            return UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: alpha)
        case "Silver":
            return UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: alpha)
        case "Asbestos":
            return UIColor(red: 127/255, green: 140/255, blue: 141/255, alpha: alpha)
        default:
            return UIColor.whiteColor();
        }
    }
}
var Globals = Globalvar();