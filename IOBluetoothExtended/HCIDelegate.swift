//
//  HCIDelegate.swift
//  IOBluetoothExtended
//
//  Created by Davide Toldo on 03.09.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

import Foundation

extension HCIDelegate: IOBluetoothHostControllerDelegate {
    public func bluetoothHCIEventNotificationMessage(_ controller: IOBluetoothHostController,
        in message: UnsafeMutablePointer<IOBluetoothHCIEventNotificationMessage>) {
        
        let opcode = message.pointee.dataInfo.opcode
        let data = IOBluetoothHCIEventParameterData(message)
        if opcode != waitingFor { return }
        
        print(#function)
        
        let dataInfo = message.pointee.dataInfo
        let opcod1 = String(format:"%02X", dataInfo.opcode)
        let opcod2 = Array(opcod1)
        let opcod3 = "\(opcod2[2])\(opcod2[3])\(opcod2[0])\(opcod2[1])"
        
        var result = "\(String(format:"%02X", dataInfo._field7))"
        result.append("\(String(format:"%02X", dataInfo.parameterSize+3))")
        result.append("01\(opcod3)")
        result.append(data.hexEncodedString())
        
        let str = result.separate()
        var str2 = ""
        for (i, sub) in str.components(separatedBy: " ").enumerated() {
            if i % 8 == 7 {
                let rowIndex = i/8
                let start = result.index(result.startIndex, offsetBy: rowIndex * 32)
                let end = rowIndex * 32 + 32 < result.count ?
                    result.index(result.startIndex, offsetBy: rowIndex * 32 + 32) :
                    result.endIndex
                let range = start..<end
                let row = String(result[range])
                str2.append(sub + " \(hexStringtoAscii(row))\n")
            }
            else {
                str2.append(sub + " ")
            }
        }
        
        print(str2)
        exit(0)
    }
    
    func hexStringtoAscii(_ hexString : String) -> String {
        
        let pattern = "(0x)?([0-9a-f]{2})"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsString = hexString as NSString
        let matches = regex.matches(in: hexString, options: [], range: NSMakeRange(0, nsString.length))
        var characters = matches.map {
            Character(UnicodeScalar(UInt32(nsString.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }
        characters = characters.map {
            if !$0.isASCII { return "." }
            if $0.asciiValue! < 32 { return "." }
            if $0.asciiValue! > 130 { return "." }
            if $0.isNewline { return "." }
            if $0 == "\0" { return "." }
            return $0
        }
        return String(characters)
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension String {
    func separate(every stride: Int = 4, with separator: Character = " ") -> String {
        return String(enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}.joined())
    }
}