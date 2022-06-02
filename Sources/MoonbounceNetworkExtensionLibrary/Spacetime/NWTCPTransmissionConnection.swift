//
//  NWTCPTransmissionConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/16/22.
//

import Foundation
import NetworkExtension

import Chord
import TransmissionTypes

public class NWTCPTransmissionConnection: TransmissionTypes.Connection
{
    let connection: NWTCPConnection
    let readGroup = DispatchGroup()
    let writeGroup = DispatchGroup()

    public convenience init?(provider: NEPacketTunnelProvider, endpoint: NWEndpoint)
    {
        let connection = provider.createTCPConnectionThroughTunnel(to: endpoint, enableTLS: false, tlsParameters: nil, delegate: nil)
        let lock = DispatchSemaphore(value: 0)
        let queue = DispatchQueue(label: "NWTCPNetworkExtension")
        var success = false
        queue.async
        {
            var running = true
            while(running)
            {
                switch connection.state
                {
                    case .cancelled:
                        success = false
                        running = false

                    case .connected:
                        success = true
                        running = false

                    case .disconnected:
                        success = false
                        running = false

                    default:
                        sleep(10) // 10 seconds
                }
            }

            lock.signal()
        }

        lock.wait()

        guard success else
        {
            return nil
        }

        self.init(connection)
    }

    public init(_ connection: NWTCPConnection)
    {
        self.connection = connection
    }

    public func read(size: Int) -> Data?
    {
        self.readGroup.enter()

        let (maybeData, maybeError): (Data?, Error?) = Synchronizer.sync2
        {
            callback in

            self.connection.readLength(size)
            {
                maybeData, maybeError in

                callback(maybeData, maybeError)
            }
        }

        self.readGroup.leave()

        if maybeError != nil
        {
            return nil
        }

        return maybeData
    }

    public func read(maxSize: Int) -> Data?
    {
        self.readGroup.enter()

        let (maybeData, maybeError): (Data?, Error?) = Synchronizer.sync2
        {
            callback in

            self.connection.readMinimumLength(1, maximumLength: maxSize)
            {
                maybeData, maybeError in

                callback(maybeData, maybeError)
            }
        }

        self.readGroup.leave()

        if maybeError != nil
        {
            return nil
        }

        return maybeData
    }

    public func readWithLengthPrefix(prefixSizeInBits: Int) -> Data?
    {
        self.readGroup.enter()

        let size: Int
        switch prefixSizeInBits
        {
            case 8:
                size = 1

            case 16:
                size = 2

            case 32:
                size = 4

            case 64:
                size = 8

            default:
                return nil
        }

        let (maybeData, maybeError): (Data?, Error?) = Synchronizer.sync2
        {
            callback in

            self.connection.readLength(size)
            {
                maybeData, maybeError in

                callback(maybeData, maybeError)
            }
        }

        if maybeError != nil
        {
            self.readGroup.leave()
            return nil
        }

        guard let data = maybeData else
        {
            self.readGroup.leave()
            return nil
        }

        let length: Int
        switch prefixSizeInBits
        {
            case 8:
                guard let uint8 = data.uint8 else
                {
                    self.readGroup.leave()
                    return nil
                }
                length = Int(uint8)

            case 16:
                guard let uint16 = data.uint16 else
                {
                    self.readGroup.leave()
                    return nil
                }
                length = Int(uint16)

            case 32:
                guard let uint32 = data.uint32 else
                {
                    self.readGroup.leave()
                    return nil
                }
                length = Int(uint32)

            case 64:
                guard let uint64 = data.uint64 else
                {
                    self.readGroup.leave()
                    return nil
                }
                length = Int(uint64)

            default:
                return nil
        }

        let (maybeData2, maybeError2): (Data?, Error?) = Synchronizer.sync2
        {
            callback in

            self.connection.readLength(length)
            {
                maybeData, maybeError in

                callback(maybeData, maybeError)
            }
        }

        if maybeError2 != nil
        {
            self.readGroup.leave()
            return nil
        }

        self.readGroup.leave()
        return maybeData2
    }

    public func write(string: String) -> Bool
    {
        self.write(data: string.data)
    }

    public func write(data: Data) -> Bool
    {
        self.writeGroup.enter()

        let maybeError = Synchronizer.sync
        {
            callback in

            self.connection.write(data)
            {
                maybeError in

                callback(maybeError)
            }
        }

        self.writeGroup.leave()

        return maybeError == nil
    }

    public func writeWithLengthPrefix(data: Data, prefixSizeInBits: Int) -> Bool
    {
        let prefix: Data
        switch prefixSizeInBits
        {
            case 8:
                let uint8 = UInt8(data.count)
                prefix = uint8.data

            case 16:
                let uint16 = UInt16(data.count)
                prefix = uint16.data

            case 32:
                let uint32 = UInt32(data.count)
                prefix = uint32.data

            case 64:
                let uint64 = UInt64(data.count)
                prefix = uint64.data

            default:
                return false
        }

        return self.write(data: prefix + data)
    }

    public func close()
    {
        self.connection.cancel()
    }
}
