//
//  NWTCPTransmissionConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/16/22.
//

import Foundation
import NetworkExtension
import os.log

import Chord
import TransmissionTypes

public class NWTCPTransmissionConnection: TransmissionTypes.Connection
{
    let logger: Logger
    let connection: NWTCPConnection
    let readWithPrefixLock = DispatchSemaphore(value: 0)
    let readGroup = DispatchGroup()
    let writeGroup = DispatchGroup()

    public convenience init?(provider: NEPacketTunnelProvider, endpoint: NWEndpoint, logger: Logger)
    {
        let connection = provider.createTCPConnectionThroughTunnel(to: endpoint, enableTLS: false, tlsParameters: nil, delegate: nil)

        self.init(connection, logger: logger)
    }

    public init?(_ connection: NWTCPConnection, logger: Logger)
    {
        self.logger = logger
        
        let lock = DispatchSemaphore(value: 0)
        let queue = DispatchQueue(label: "NWTCPNetworkExtension")
        var success = false
        // FIXME: Use KVO to get state
        queue.async
        {
            var running = true
            
            while(running)
            {
                switch connection.state
                {
                    case .cancelled:
                        logger.log("🛑 NWTCPTransmissionConnection: connection state is cancelled.")
                        success = false
                        running = false

                    case .connected:
                        logger.log("✅ NWTCPTransmissionConnection: connection state is connected.")
                        success = true
                        running = false

                    case .disconnected:
                        logger.log("🪩 🥅 NWTCPTransmissionConnection: connection state is connected.")
                        success = false
                        running = false

                    default:
                        logger.log("❓NWTCPTransmissionConnection: connection state is ??. Waiting 1 second...")
                        sleep(1) // 1 second
                }
            }

            lock.signal()
        }

        lock.wait()

        guard success else
        {
            return nil
        }
        
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
        
        // If we get an empty data return nil
        if let someData = maybeData
        {
            if someData.isEmpty
            {
                return nil
            }
        }

        return maybeData
    }

    public func unsafeRead(size: Int) -> Data?
    {
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
            return nil
        }

        // If we get an empty data return nil
        if let someData = maybeData
        {
            if someData.isEmpty
            {
                return nil
            }
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
        
        // If we get an empty data return nil
        if let someData = maybeData
        {
            if someData.isEmpty
            {
                return nil
            }
        }

        return maybeData
    }

    public func readWithLengthPrefix(prefixSizeInBits: Int) -> Data?
    {
        // FIXME: The read locks for this class need to be finessed so that we don't interweave reads incorrectly
        self.logger.log("NWTCPConnection.readWithLengthPrefix: entering read lock")
        readWithPrefixLock.wait()
        self.logger.log("NWTCPConnection.readWithLengthPrefix: attempting to read data")
        let maybeData = TransmissionTypes.readWithLengthPrefix(prefixSizeInBits: prefixSizeInBits, connection: self)
        self.logger.log("NWTCPConnection.readWithLengthPrefix: attempting read \(maybeData.debugDescription, privacy: .public) bytes")
        readWithPrefixLock.signal()
        self.logger.log("NWTCPConnection.readWithLengthPrefix: leaving read lock")
        
        return maybeData
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
        self.logger.log("🔌 NWTCPConnection.writeWithLengthPrefix")
        let result = TransmissionTypes.writeWithLengthPrefix(data: data, prefixSizeInBits: prefixSizeInBits, connection: self)
        self.logger.log("🔌 NWTCPConnection.writeWithLengthPrefix: success? \(result.description, privacy: .public)")
        
        return result
    }

    public func close()
    {
        self.connection.cancel()
    }
}
