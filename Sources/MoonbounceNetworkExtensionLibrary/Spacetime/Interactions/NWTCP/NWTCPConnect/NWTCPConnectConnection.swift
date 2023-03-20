//
//  NWTCPConnectConnection.swift
//
//
//  Created by Dr. Brandon Wiley on 2/4/22.
//

import Foundation

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Chord
import Datable
import Spacetime
import TransmissionTypes
import Universe

public class NWTCPConnectConnection: TransmissionTypes.Connection
{
    
    public let universe: Universe
    public let uuid: UUID
    public let logger: Logger

    public convenience init?(universe: Universe, address: String, port: Int)
    {
        let result = universe.processEffect(NWTCPConnectRequest(address, port))
        switch result
        {
            case let response as NWTCPConnectResponse:
                self.init(universe: universe, response.socketId)
                return
            case is Failure:
                return nil
            default:
                return nil
        }
    }

    public init(universe: Universe, _ uuid: UUID)
    {
        self.universe = universe
        self.uuid = uuid
        self.logger = universe.logger
    }

    public func read(size: Int) -> Data?
    {
        return self.read(.exactSize(size))
    }

    public func read(maxSize: Int) -> Data?
    {
        return self.read(.maxSize(maxSize))
    }

    public func readWithLengthPrefix(prefixSizeInBits: Int) -> Data?
    {
        self.universe.logger.log("🔌 NWTCPConnectConnection readWithLengthPrefix")
        return self.read(.lengthPrefixSizeInBits(prefixSizeInBits))
    }

    public func write(string: String) -> Bool
    {
        return self.write(data: string.data)
    }

    public func write(data: Data) -> Bool
    {
        return self.spacetimeWrite(data: data)
    }

    public func writeWithLengthPrefix(data: Data, prefixSizeInBits: Int) -> Bool
    {
        self.universe.logger.log("🔌 NWTCPConnectConnection writeWithLengthPrefix")
        return self.spacetimeWrite(data: data, prefixSizeInBits: prefixSizeInBits)
    }

    public func close()
    {
        let result = self.universe.processEffect(NWTCPCloseRequest(self.uuid))
        switch result
        {
            case is NWTCPCloseResponse:
                return
            default:
                return
        }
    }

    func read(_ style: NetworkConnectReadStyle) -> Data?
    {
        self.universe.logger.log("🔌 NWTCPConnectConnection read with style: \(style.description)")
        let result = self.universe.processEffect(NWTCPReadRequest(self.uuid, style))
        self.universe.logger.log("🔌 NWTCPConnectConnection read with style result: \(result)")
        switch result
        {
            case let response as NWTCPReadResponse:
                return response.data

            default:
                return nil
        }
    }
    
    public func unsafeRead(size: Int) -> Data?
    {
        return self.read(.unsafeExactSize(size))
    }

    public func spacetimeWrite(data: Data, prefixSizeInBits: Int? = nil) -> Bool
    {
        self.universe.logger.log("🔌 NWTCPConnectConnection spacetimeWrite with prefixSizeInBits: \(prefixSizeInBits.debugDescription)")
        let result = self.universe.processEffect(NWTCPWriteRequest(self.uuid, data, prefixSizeInBits))
        switch result
        {
            case is NWTCPWriteResponse:
                return true
            default:
                return false
        }
    }
}

extension Universe
{
    public func connect(_ address: String, _ port: Int, _ type: ConnectionType = .tcp) throws -> Connection
    {
        switch type
        {
            case .tcp:
                guard let connection = NWTCPConnectConnection(universe: self, address: address, port: port) else
                {
                    throw NWTCPConnectConnectionError.connectionRefused
                }

                return connection

            case .udp:
                throw NWTCPConnectConnectionError.unimplemented
        }
    }
}

public enum NWTCPConnectConnectionError: Error
{
    case connectionRefused
    case unimplemented
}
