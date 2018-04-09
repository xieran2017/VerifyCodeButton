//
//  ViewController.swift
//  SmsCodeButton
//
//  Created by xieran on 2018/3/28.
//  Copyright © 2018年 xieran. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let btn = VerifyCodeButton(buttonType: .simple, identifier: "123")
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        btn.center = self.view.center
        view.addSubview(btn)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

