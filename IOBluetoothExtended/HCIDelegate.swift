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
        
        DispatchQueue.global(qos: .background).async {
            self.startupServer()
        }
    }

    public func sendOverTCP(data: Data, _ hostUDP: NWEndpoint.Host, _ portUDP: NWEndpoint.Port) {
        let connection = NWConnection(host: hostUDP, port: portUDP, using: .tcp)
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
        let h = NWEndpoint.Host(self.hostname as String)
        let i = NWEndpoint.Port(self.inject as String)
        let s = NWEndpoint.Port(self.snoop as String)

        let sock_fd = socket(AF_INET, SOCK_STREAM, 0)
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

        if listen(sock_fd, 5) == -1 {
            perror("Failure: listening")
            exit(EXIT_FAILURE)
        }

        print("IOBE: Listening on", server_addr.sin_port.bigEndian)
        while !self.exit_requested {
            var client_addr = sockaddr_storage()
            var client_addr_len = socklen_t(MemoryLayout.size(ofValue: client_addr))
            let client_fd = withUnsafeMutablePointer(to: &client_addr) {
                accept(sock_fd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &client_addr_len)
            }
            if client_fd == -1 {
                perror("Failure: accepting connection")
                exit(EXIT_FAILURE);
            }

//            let fileHandle = FileHandle(fileDescriptor: client_fd)
//            let data = fileHandle.readDataToEndOfFile()
//            print("Command: \(data as NSData)")
            //  TODO: - Send command to chip here
            self.waitingFor = 0xfc4d

            let temp = "040E0C01011000066724060f009641".hexadecimal!
            self.sendOverTCP(data: temp, h, s!)
        }
        print("Exiting...")
        close(sock_fd);
        close(client_fd);
    }
    
    public func bluetoothHCIEventNotificationMessage(_ controller: IOBluetoothHostController,
        in message: UnsafeMutablePointer<IOBluetoothHCIEventNotificationMessage>) {
        
        let opcode = message.pointee.dataInfo.opcode
        let data = IOBluetoothHCIEventParameterData(message)
        if opcode != waitingFor { return }
        
        let dataInfo = message.pointee.dataInfo
        let opcod1 = String(format:"%02X", dataInfo.opcode)
        let opcod2 = Array(opcod1)
        let opcod3 = "\(opcod2[2])\(opcod2[3])\(opcod2[0])\(opcod2[1])"
        
        var result = "\(String(format:"%02X", dataInfo._field7))"
        result.append("\(String(format:"%02X", dataInfo.parameterSize+3))")
        result.append("01\(opcod3)")
        result.append(data.hexEncodedString())
        
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

        let hostname = NWEndpoint.Host(self.hostname as String)
        guard let port = NWEndpoint.Port(self.snoop as String) else { return }

//        print(formatted)
        self.sendOverTCP(data: result.hexadecimal!, hostname, port)
    }
}
