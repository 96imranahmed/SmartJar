//
//  ViewController.swift
//  SimpleBuy
//
//  Created by Imran Ahmed on 09/01/2016.
//  Copyright © 2016 JOAI. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceScan: UIViewController, BLEDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    @IBOutlet weak var table: UITableView!
    var scan_active:Bool = false;
    var detaildevice:Device = Device();
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false;
        Globals.ble_dev.delegate = self;
        table.delegate = self;
        table.dataSource = self;
        Utils.sortDevices();
        Utils.getSessionKey("");
        self.navigationItem.title = "Welcome!" // "Hi " + Globals.user.name! + "!";
        self.navigationItem.rightBarButtonItem = self.editButtonItem();
        Globals.registered_devices = [Device(name: "Coffee", UUID: "1", date: NSDate(), mass: 1.0, product: ""), Device(name: "Sugar", UUID: "2", date: NSDate(), mass:1.0, product: "")];
        // Do any additional setup after loading the view, typically from a nib.
        let recog:UIGestureRecognizer = UIGestureRecognizer(target: self, action: "irrelevantfunc:");
        recog.delegate = self;
        self.view.addGestureRecognizer(recog);
    }
    override func viewDidAppear(animated: Bool) {
        //Utils.disp(self, title: "Starting scan!", message: "Scanning!")
        if !scan_active {
            scan_active = true;
            startScan()
        }
        table.reloadData();
    }
    func startScan() {
        if (!scan_active) {
            scan_active = true;
            if ((Globals.ble_dev.activePeripheral) != nil) {
                if(Globals.ble_dev.activePeripheral!.state == CBPeripheralState.Connected)
                {
                    Globals.ble_dev.centralManager.cancelPeripheralConnection(Globals.ble_dev.activePeripheral!);
                }
                
            }
            Globals.ble_dev.startScanning(Globals.scan_timeout);
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated);
        table.setEditing(editing, animated: animated);
    }
    //Gesture recognizer delegates
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if !scan_active {
            startScan()
        }
        return false;
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "LoadDetail") {
            if let VC:DeviceDetail = segue.destinationViewController as? DeviceDetail {
                VC.curdevice = detaildevice;
            }
        }
    }
    //Table View Delegate Functions
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        Utils.sortDevices();
        if (Globals.registered_devices.count > 0 && Globals.cur_devices.count > 0) {
            if (indexPath.section == 0) {
                let cell = table.dequeueReusableCellWithIdentifier("DetailCell") as! DetailCell;
                cell.detailDevice = Globals.registered_devices[indexPath.row];
                cell.performSetup();
                return cell;
            } else {
                let cell = table.dequeueReusableCellWithIdentifier("DetailCell") as! DetailCell;
                cell.detailDevice = Device();
                cell.performSetup();
                return cell;
            }
        } else {
            if (Globals.registered_devices.count > 0) {
                let cell = table.dequeueReusableCellWithIdentifier("DetailCell") as! DetailCell;
                cell.detailDevice = Globals.registered_devices[indexPath.row];
                cell.performSetup();
                return cell;
            } else if (Globals.cur_devices.count > 0) {
                let cell = table.dequeueReusableCellWithIdentifier("DetailCell") as! DetailCell;
                cell.detailDevice = Device();
                cell.performSetup();
                return cell;
            } else {
                return UITableViewCell();
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (Globals.registered_devices.count > 0 && Globals.cur_devices.count > 0) {
            if (section == 0) {
                return Globals.registered_devices.count;
            } else {
                return Globals.cur_devices.count;
            }
            
        } else {
            if (Globals.registered_devices.count > 0) {
                return Globals.registered_devices.count;
            } else if (Globals.cur_devices.count > 0) {
                return Globals.cur_devices.count;
            } else {
                return 0;
            }
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (Globals.registered_devices.count > 0 && Globals.cur_devices.count > 0) {
            if (section == 0) {
                return "My Devices";
            } else {
                return "Detected Devices";
            }
        } else {
            if (Globals.registered_devices.count > 0) {
                return "My Devices";
            } else if (Globals.cur_devices.count > 0) {
                return "Detected Devices";
            } else {
                return "";
            }
        }
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if tableView.editing {
            if (Globals.registered_devices.count > 0 && Globals.cur_devices.count > 0) {
                if (indexPath.section == 0) {
                    return true;
                } else {
                    return false;
                }
                
            } else {
                if (Globals.registered_devices.count > 0) {
                    return true;
                } else if (Globals.cur_devices.count > 0) {
                    return false;
                } else {
                    return false;
                }
            }
        } else { return false;}
        
    }
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Remove?";
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            //Perform delete!
            Globals.registered_devices.removeAtIndex(indexPath.row);
            tableView.reloadData();
            //Start scan!
            if !scan_active {
                startScan()
            }
        }
    }
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let cell = table.cellForRowAtIndexPath(indexPath) as? DetailCell;
        detaildevice = (cell?.detailDevice)!;
        self.performSegueWithIdentifier("LoadDetail", sender: self);
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = table.cellForRowAtIndexPath(indexPath) as? DetailCell;
        detaildevice = (cell?.detailDevice)!;
        if (detaildevice.connected) {
            if let index = Globals.ble_dev.peripherals.indexOf({$0.identifier.UUIDString == detaildevice.UUID}) {
                let object = Globals.ble_dev.peripherals[index];
                Globals.ble_dev.connectToPeripheral(object);
                Globals.ble_dev.activePeripheral?.readValueForCharacteristic(Globals.ble_dev.characteristics[Globals.ble_dev.RBL_CHAR_TXTWO_UUID]!);
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
    }
    //BLE Delegate Functions
    func bleDidConnectToPeripheral() {
        dispatch_async(dispatch_get_main_queue() , {
            RKDropdownAlert.title("Connected to BLE", backgroundColor:  Utils.returnColor("Peter River", alpha: 1.0), textColor: UIColor.whiteColor(), time: 3);
        });
    }
    func bleDidDisconnectFromPeripheral() {
    }
    func bleDidUpdateState(state: CBCentralManagerState) {
        if (state != CBCentralManagerState.PoweredOn) {
            scan_active = false;
            if (state == CBCentralManagerState.PoweredOff) {
                dispatch_async(dispatch_get_main_queue() , {
                    RKDropdownAlert.title("Bluetooth Disabled - Enable in Settings", backgroundColor:  Utils.returnColor("Alizarin", alpha: 1.0), textColor: UIColor.whiteColor(), time: 3);
                });
            } else {
                if (state != CBCentralManagerState.Unknown) {
                    dispatch_async(dispatch_get_main_queue() , {
                        RKDropdownAlert.title("Bluetooth Error - Restart App!", backgroundColor:  Utils.returnColor("Alizarin", alpha: 1.0), textColor: UIColor.whiteColor(), time: 3);
                    });
                }
            }
        }
    }
    func bleDidReceiveData(data: NSData?) {
        var output: Int = 0;
        print(data?.length);
        data?.getBytes(&output, length: (data?.length)!);
        if let index = Globals.registered_devices.indexOf({$0.UUID == Globals.cur_devices[0].identifier.UUIDString}) {
            Globals.registered_devices[index].mass = Double(output);
        }
    }
    func bleDidDiscoverNewDevice(UUID: String) {
        if (Globals.registered_devices.indexOf({$0.UUID == UUID}) == nil) {
            Globals.registered_devices.append(Device(UUID: UUID));
        } else {}
        Utils.verifyRegisteredDevices();
        dispatch_async(dispatch_get_main_queue() , {
            self.table.reloadData();
        });
    }
    func bleDidStopScan() {
        Utils.verifyRegisteredDevices();
        scan_active = false;
        //Scan again
        dispatch_async(dispatch_get_main_queue() , {
        });
        
    }
}

