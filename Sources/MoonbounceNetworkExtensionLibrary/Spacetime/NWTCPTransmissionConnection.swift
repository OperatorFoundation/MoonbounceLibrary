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
import TransmissionBase
import TransmissionTypes

public class NWTCPTransmissionConnection: BaseConnection
{
    let logger: Logger
    let connection: NWTCPConnection
    let readWithPrefixLock = DispatchSemaphore(value: 0)

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
        let uuid = UUID()
        let id = uuid.hashValue
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
        super.init(id: id)
    }

    // FIXME: remove the override keyword
    override public func networkRead(size: Int) throws -> Data
    {
        self.logger.log("NWTCPTransmissionConnection.networkRead(size: \(size)) called")
        let (maybeData, maybeError): (Data?, Error?) = Synchronizer.sync2
        {
            callback in

            self.connection.readLength(size)
            {
                maybeData, maybeError in

                callback(maybeData, maybeError)
            }
        }

        if let error = maybeError
        {
            throw error
        }
        
        // If we get an empty data return nil
        if let someData = maybeData
        {
            if someData.isEmpty
            {
                throw NWTCPTransmissionConnectionError.readFailed
            } else {
                return someData
            }
        } else {
            throw NWTCPTransmissionConnectionError.readFailed
        }
    }

    override public func networkWrite(data: Data) throws
    {
        let maybeError = Synchronizer.sync
        {
            callback in

            self.connection.write(data)
            {
                maybeError in

                callback(maybeError)
            }
        }

        if let error = maybeError {
            throw error
        }
    }

    override public func close()
    {
        self.connection.cancel()
    }
}

public enum NWTCPTransmissionConnectionError: Error {
    case readFailed
    case writeFailed
}
