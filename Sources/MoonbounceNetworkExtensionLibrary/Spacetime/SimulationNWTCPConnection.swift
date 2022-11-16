//
//  SimulationNWTCPConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/17/22.
//

import Foundation
import os.log

import Chord
import Spacetime
import TransmissionTypes

public class SimulationNWTCPConnection
{
    public var logger: Logger?
    
    let networkConnection: TransmissionTypes.Connection
    fileprivate var reads: [UUID: Read] = [:]
    fileprivate var writes: [UUID: Write] = [:]
    fileprivate var closes: [UUID: Close] = [:]

    public init(_ networkConnection: TransmissionTypes.Connection, logger: Logger?)
    {
        self.logger = logger
        self.networkConnection = networkConnection
        
        self.logger?.log("🌝 SimulationNWTCPConnection created")
    }

    public func read(request: NWTCPReadRequest, channel: BlockingQueue<Event>)
    {
        self.logger?.log("🌝 SimulationNWTCPConnection.read(): \(request.description, privacy: .public)")
        
        let read = Read(simulationConnection: self, networkConnection: self.networkConnection, request: request, events: channel, logger: logger)
        self.reads[read.uuid] = read
    }

    public func write(request: NWTCPWriteRequest, channel: BlockingQueue<Event>)
    {
        self.logger?.log("🌝 SimulationNWTCPConnection.write(): \(request.description, privacy: .public)")
        
        let write = Write(simulationConnection: self, networkConnection: self.networkConnection, request: request, events: channel, logger: logger)
        self.writes[write.uuid] = write
    }

    public func close(request: NWTCPCloseRequest, state: NetworkExtensionModule, channel: BlockingQueue<Event>)
    {
        self.logger?.log("🌝 SimulationNWTCPConnection.close(): \(request.description, privacy: .public)")
        let close = Close(simulationConnection: self, networkConnection: self.networkConnection, state: state, request: request, events: channel)
        self.closes[close.uuid] = close
    }
}

fileprivate struct Read
{
    public var logger: Logger? = nil
    let simulationConnection: SimulationNWTCPConnection
    let networkConnection: TransmissionTypes.Connection
    let request: NWTCPReadRequest
    let events: BlockingQueue<Event>
    let queue = DispatchQueue(label: "SimulationConnection.Read")
    let response: NWTCPReadResponse? = nil
    let uuid = UUID()

    public init(simulationConnection: SimulationNWTCPConnection, networkConnection: TransmissionTypes.Connection, request: NWTCPReadRequest, events: BlockingQueue<Event>, logger: Logger?)
    {
        self.simulationConnection = simulationConnection
        self.networkConnection = networkConnection
        self.request = request
        self.events = events
        self.logger = logger

        let uuid = self.uuid

        self.queue.async
        {
            switch request.style
            {
                case .exactSize(let size):
                    guard let result = networkConnection.read(size: size) else
                    {
                        let failure = Failure(request.id)
                        print(failure.description)
                        events.enqueue(element: failure)
                        return
                    }

                    let response = NWTCPReadResponse(request.id, request.socketId, result)
                    print(response.description)
                    events.enqueue(element: response)
                case .maxSize(let size):
                    guard let result = networkConnection.read(maxSize: size) else
                    {
                        let failure = Failure(request.id)
                        print(failure.description)
                        events.enqueue(element: failure)
                        return
                    }

                    let response = NWTCPReadResponse(request.id, request.socketId, result)
                    print(response.description)
                    events.enqueue(element: response)
                case .lengthPrefixSizeInBits(let prefixSize):
                    logger?.log("SimulationNWTCPConnection.Read: lengthPrefixSizeInBits connection is a \(type(of: networkConnection), privacy: .public)")
                    guard let result = networkConnection.readWithLengthPrefix(prefixSizeInBits: prefixSize) else
                    {
                        let failure = Failure(request.id)
                        print(failure.description)
                        events.enqueue(element: failure)
                        return
                    }

                    let response = NWTCPReadResponse(request.id, request.socketId, result)
                    print(response.description)
                    events.enqueue(element: response)
            }

            simulationConnection.reads.removeValue(forKey: uuid)
        }
    }
}

fileprivate struct Write
{
    public var logger: Logger? = nil
    let simulationConnection: SimulationNWTCPConnection
    let networkConnection: TransmissionTypes.Connection
    let request: NWTCPWriteRequest
    let events: BlockingQueue<Event>
    let queue = DispatchQueue(label: "SimulationConnection.Write")
    let uuid = UUID()

    public init(simulationConnection: SimulationNWTCPConnection, networkConnection: TransmissionTypes.Connection, request: NWTCPWriteRequest, events: BlockingQueue<Event>, logger: Logger? = nil)
    {
        self.simulationConnection = simulationConnection
        self.networkConnection = networkConnection
        self.request = request
        self.events = events
        self.logger = logger

        let uuid = self.uuid

        queue.async
        {
            if let prefixSize = request.lengthPrefixSizeInBits
            {
                guard networkConnection.writeWithLengthPrefix(data: request.data, prefixSizeInBits: prefixSize) else
                {
                    let failure = Failure(request.id)
                    events.enqueue(element: failure)
                    return
                }

                let response = NWTCPWriteResponse(request.id, uuid)
                print(response.description)
                events.enqueue(element: response)
            }
            else
            {
                guard networkConnection.write(data: request.data) else
                {
                    let failure = Failure(request.id)
                    print(failure.description)
                    events.enqueue(element: failure)
                    return
                }

                let response = NWTCPWriteResponse(request.id, uuid)
                print(response.description)
                events.enqueue(element: response)
            }

            simulationConnection.writes.removeValue(forKey: uuid)
        }
    }
}

fileprivate struct Close
{
    let simulationConnection: SimulationNWTCPConnection
    let networkConnection: TransmissionTypes.Connection
    let request: NWTCPCloseRequest
    let state: NetworkExtensionModule
    let events: BlockingQueue<Event>
    let queue = DispatchQueue(label: "SimulationConnection.Close")
    let uuid = UUID()

    public init(simulationConnection: SimulationNWTCPConnection, networkConnection: TransmissionTypes.Connection, state: NetworkExtensionModule, request: NWTCPCloseRequest, events: BlockingQueue<Event>)
    {
        self.simulationConnection = simulationConnection
        self.networkConnection = networkConnection
        self.state = state
        self.request = request
        self.events = events

        let uuid = self.uuid

        queue.async
        {
            networkConnection.close()

            let response = NWTCPCloseResponse(request.id, socketId: uuid)
            print(response.description)
            events.enqueue(element: response)

            state.connections.removeValue(forKey: uuid)
            simulationConnection.closes.removeValue(forKey: uuid)
        }
    }
}
