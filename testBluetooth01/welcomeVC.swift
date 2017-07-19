//
//  welcomeVC.swift
//  testBluetooth01
//
//  Created by 陳信毅 on 2017/7/19.
//  Copyright © 2017年 陳信毅. All rights reserved.
//

import UIKit

class welcomeVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func Next(_ sender: Any) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "VC"){
            show(vc, sender: self)
        }
        
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
