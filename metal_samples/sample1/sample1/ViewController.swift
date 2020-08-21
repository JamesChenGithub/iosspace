//
//  ViewController.swift
//  sample1
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var labelTest: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        let devices = MTLCopyAllDevices();
        
        guard let _ = devices.first else {
            fatalError("You GPU does not support the Metal");
        }
        
        labelTest.stringValue = "Your system has the following GPU(s) : \n"
        for device in devices {
            labelTest.stringValue += "\(device.name)\n"
        }
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

