//
//  ViewController.swift
//  testBluetooth
//
//  Created by 陳信毅 on 2017/7/15.
//  Copyright © 2017年 陳信毅. All rights reserved.
//

import UIKit
import CoreBluetooth

enum SendDataError:Error {
    case CharacteristicNotFound
}
class ViewController: UIViewController, CBCentralManagerDelegate ,CBPeripheralDelegate,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tabelView: UITableView!
    
    
    let UUID_SERVICE = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    //读特征的UUID字符串
    let UUID_READ_CHARACTER = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    //写特征的UUID字符串
    let UUID_WRITE_CHARACTER = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    
    var centralManager: CBCentralManager!
    
    var connectPeripheral : CBPeripheral!
    
    var charDictionary = [String: CBCharacteristic]()
    
    var peripherals = Array<CBPeripheral>()
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let queue = DispatchQueue.global()
        centralManager = CBCentralManager(delegate: self, queue: queue)
        
    }
    
    //tableView 處理
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = peripherals[indexPath.row].name
        
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        connectPeripheral = peripherals[indexPath.row]
        connectPeripheral.delegate = self
        centralManager.connect(peripherals[indexPath.row], options: nil)
        
        
    }
    
    
    //藍牙scan處理
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //如果藍牙沒開的話就return
        guard central.state == .poweredOn else {
            return
        }
        //只scan有UUID_SERVICE的藍芽服務
        let id = CBUUID(string: UUID_SERVICE)
        centralManager.scanForPeripherals(withServices: [id], options: nil)
    }
    
    //找出符合的設備
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let uuidString = peripheral.identifier.uuidString
        for i in peripherals{
            if uuidString == i.identifier.uuidString{
                return
            }
        }
        if let _ = peripheral.name{
            peripherals.append(peripheral)
            
        }
        tabelView.reloadData()
        print("找到藍牙裝置：\(peripheral.name)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        centralManager.stopScan()
    }
    //當斷線時重新準備連線
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("連線中斷")
        centralManager.connect(peripheral, options: nil)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file,#function)")
            
            return
        }
        for service in peripheral.services! {
            connectPeripheral.discoverCharacteristics(nil, for: service)
            print(service.uuid)
            
        }

    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file,#function)")
            return
        }
        
        for characteristic in service.characteristics!{
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            print(uuidString)
        }
        //如果有找到UUID_READ_CHARACTER則訂閱，否則切斷連線
        if let characteristic = charDictionary[UUID_READ_CHARACTER]{
            connectPeripheral.setNotifyValue(true, for: characteristic)
        }else{
            centralManager.cancelPeripheralConnection(connectPeripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file,#function)")
            print(error!)
            return
        }
        //讀取資料的處理
        if characteristic.uuid.uuidString == UUID_READ_CHARACTER{
            var n:Array<UInt8> = Array(repeating: 0, count: 14)
            let data = characteristic.value!
            data.copyBytes(to: &n, count: 14)
            receiveData(Byte: n)

        }
    }
    //體重轉換
    func weightChange(h:UInt8 ,l:UInt8){
        var weightValue:CGFloat = ((CGFloat(h&0x3F)*256+CGFloat(l)))
//        unit = weighth&0b11000000;
        print(weightValue)
        if((h&0b11000000)==0b01000000){
//            单位为ST
            
            var weight:Int = (Int(weightValue*22046/1000+5)/10)&0xfffe

//            unitLabel.text = @"ST:lb";
//            weightTF.text = [NSString stringWithFormat:@"%ld:%ld",weight/140,(weight%140)/10];
        }else {
            if((h&0b11000000)==0b00000000){
                //单位为斤
                weightValue /= 2.0;
//                unitLabel.text = @"斤";
            }else if((h&0b11000000)==0b10000000){
                //单位为公斤
//                unitLabel.text = @"公斤";
            }else{
                //单位为lb
//                weightValue = ((NSInteger)(weightValue*22046/1000+5)/10)&0xfffe;
//                unitLabel.text = @"lb";
            }
//            weightTF.text = [NSString stringWithFormat:@"%.1f",weightValue/10.0];
            print(weightValue/10)
        }
    }
    
    //發送資料
    func sendData(data: Data , uuidString: String) throws{
        guard let characteristic = charDictionary[uuidString] else {
            throw SendDataError.CharacteristicNotFound
        }
        if uuidString == UUID_WRITE_CHARACTER{
            connectPeripheral.writeValue(data, for: characteristic, type: .withResponse)
//           print("OK")
        }
    }
    
//寫入檔案
    @IBAction func writeBody(_ sender: Any) {
        
        var param : Array<UInt8> = Array(repeating: 0, count: 14)
        param[0] = 0x5A;
        param[1] = 0xd5;
        param[2] = 1;   //用户组1，1~8
        param[3] = 20;  //年齡18-99
        param[4] = 0;   //性別：女0 男1
        param[5] = 2;  // 身高单位 1 ~ inch  2 ~ cm
        param[6] = 160; // 身高
        param[8] = 0x80;  //
        param[13] = 0xaa;
        var checksum : UInt8 = 0
        for i in 0..<12 {
            checksum ^= param[i]
        }
        param[12] = checksum
        
        let data = Data(bytes: param)
        do{
            try sendData(data: data, uuidString: UUID_WRITE_CHARACTER)
   
        }catch{
            print(error)
        }
        
    }
    
    func receiveData(Byte: Array<UInt8>){
        var n = Byte
        //是否要回送資料
        var fAck = true
        //判定傳來什麼資料
        switch n[1] {
        //臨時體重
        case 0xd1:
            fAck = false
        //穩定體重
        case 0xd2:
            //                var weight = 0.0
            print(n)
            weightChange(h: n[2], l: n[3])
        //相關數值
        case 0xd3:
            let nameArr = ["体脂率","水分率","肌肉量","骨量","内脏脂肪","BMI"]
            let bodyfat = (Double(n[2])*256 + Double(n[3]))/10
            let water = (Double(n[4])*256 + Double(n[5]))/10
            let muscle = (Double(n[6])*256 + Double(n[7]))/10
            let bone = Double(n[8]) / 10
            let vfal = Double(n[9])
            let bmi = (Double(n[10])*256 + Double(n[11]))/10
            let valueArr = [bodyfat,water,muscle,bone,vfal,bmi]
            for i in 0..<nameArr.count{
                print("\(nameArr[i]): \(valueArr[i])")
            }
        //查詢藍牙狀態
        case 0xd4:
            app.connectPeripheral = connectPeripheral
            app.centralManager = centralManager
            print(n)

        case 0xd5:
            fAck = false
        default:
            break
        }
        //回應
        if fAck {
            var checksum : UInt8 = 0
            for i in 0..<12 {
                checksum ^= n[i]
            }
            n[12] = checksum
            let data = Data(bytes: n)
            do{
                try sendData(data: data, uuidString: UUID_WRITE_CHARACTER)
            }catch{
                print(error)
            }
            if let vc = storyboard?.instantiateViewController(withIdentifier: "bodyVC"){
                show(vc, sender: self)
            }
            print(n)
        }
    }
    
    
    
}

