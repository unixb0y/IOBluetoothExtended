//
//  HCIDelegate.swift
//  IOBluetoothExtended
//
//  Created by Davide Toldo on 03.09.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

import Foundation
import Network

extension HCIDelegate: IOBluetoothHostControllerDelegate {
    @objc public func initServer() {
        print("IOBE: Initializing, snoop: \(snoop ?? "-1"), inject: \(inject ?? "-1")")
        self.startupServer()
    }

    public func sendOverTCP(data: Data, _ hostUDP: NWEndpoint.Host, _ portUDP: NWEndpoint.Port) {
        let connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        connection.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
                    if (NWError != nil) {
                        print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
                    }
                })))
            default: print("")
            }
        }
        connection.start(queue: .global())
    }
    
    private func startupServer() {
        let i = NWEndpoint.Port(self.inject as String)

        let sock_fd = socket(AF_INET, SOCK_DGRAM, 0)
        if sock_fd == -1 {
            perror("Failure: creating socket")
            exit(EXIT_FAILURE)
        }

        var sock_opt_on = Int32(1)
        setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, &sock_opt_on, socklen_t(MemoryLayout.size(ofValue: sock_opt_on)))

        var server_addr = sockaddr_in()
        let server_addr_size = socklen_t(MemoryLayout.size(ofValue: server_addr))
        server_addr.sin_len = UInt8(server_addr_size)
        server_addr.sin_family = sa_family_t(AF_INET) // chooses IPv4
        server_addr.sin_port = UInt16(i!.rawValue).bigEndian // chooses the port

        let bind_server = withUnsafePointer(to: &server_addr) {
            Darwin.bind(sock_fd, UnsafeRawPointer($0).assumingMemoryBound(to: sockaddr.self), server_addr_size)
        }
        if bind_server == -1 {
            perror("Failure: binding port")
            exit(EXIT_FAILURE)
        }

        print("IOBE: Listening on", server_addr.sin_port.bigEndian)
        DispatchQueue.global(qos: .background).async {
            while !self.exit_requested {
                var client_addr = sockaddr_storage()
                var client_addr_len = socklen_t(MemoryLayout.size(ofValue: client_addr))
                
                var receiveBuffer = [UInt8](repeating: 0, count: 1024)
                var bytesRead = 0
                
                bytesRead = withUnsafeMutablePointer(to: &client_addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        recvfrom(sock_fd, &receiveBuffer, 1024, 0, $0, &client_addr_len)
                    }
                }
                
                if bytesRead == -1 {
                    perror("Failure: error while reading")
                    exit(EXIT_FAILURE)
                }
                
                var command = Array([UInt8](receiveBuffer).dropFirst())
                let opcode: [UInt8] = Array([UInt8](receiveBuffer)[1...2])
                self.waitingFor = UInt16(opcode[1]) << 8 + UInt16(opcode[0])
                
                HCICommunicator.sendArbitraryCommand4(&command, len: 8)
            }
            print("Exiting...")
            close(self.sock_fd)
            close(self.client_fd)
        }
    }
    
    @objc(BluetoothHCIEventNotificationMessage:inNotificationMessage:)
    public func bluetoothHCIEventNotificationMessage(_ controller: IOBluetoothHostController,
        in message: UnsafeMutablePointer<IOBluetoothHCIEventNotificationMessage>) {
        
        let opcode = message.pointee.dataInfo.opcode
        let data = IOBluetoothHCIEventParameterData(message)
        if opcode != waitingFor { return }
        
        let dataInfo = message.pointee.dataInfo
        let opcod1 = String(format:"%02X", dataInfo.opcode)
        let opcod2 = Array(opcod1)
        let opcod3 = "\(opcod2[2])\(opcod2[3])\(opcod2[0])\(opcod2[1])"
        
        var result = "04"
        result.append(String(format:"%02X", dataInfo._field7))
        result.append("\(String(format:"%02X", dataInfo.parameterSize+3))")
        result.append("01\(opcod3)")
        result.append(data.hexEncodedString())
        
//        printFormatted(result)

        let h = NWEndpoint.Host(self.hostname as String)
        let s = NWEndpoint.Port(self.snoop as String)
        
        if opcode == 0x1001 {
            var temp = ""
            for i in [0,1,2,3,4,5,9,8,14,15,12,6,7,10,11] {
                temp.append(result[i*2])
                temp.append(result[i*2+1])
            }
            self.sendOverTCP(data: temp.hexadecimal!, h, s!)
        }
        else {
            let temp = result.hexadecimal!
            self.sendOverTCP(data: temp, h, s!)
        }
    }
    
    func printFormatted(_ result: String) {
        let str = result.separate()
        var formatted = ""
        for (i, sub) in str.components(separatedBy: " ").enumerated() {
            if i % 8 == 7 {
                let rowIndex = i/8
                let start = result.index(result.startIndex, offsetBy: rowIndex * 32)
                let end = rowIndex * 32 + 32 < result.count ?
                    result.index(result.startIndex, offsetBy: rowIndex * 32 + 32) :
                    result.endIndex
                let range = start..<end
                let row = String(result[range])
                formatted.append(sub + " \(row.toAscii())\n")
            }
            else {
                formatted.append(sub + " ")
            }
        }

        print(formatted)
    }
}
