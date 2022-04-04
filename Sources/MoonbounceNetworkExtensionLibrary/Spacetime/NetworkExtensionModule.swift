//
//  NetworkExtensionModule.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Chord
import Foundation
import NetworkExtension
import Simulation
import Spacetime

public class NetworkExtensionModule: Module
{
    static public let name = "NetworkExtension"

    var configuration: NETunnelProviderProtocol? = nil
    let startTunnelQueue = BlockingQueue<Error?>()
    let stopTunnelLock = DispatchSemaphore(value: 0)
    let appMessageQueue = BlockingQueue<Data?>()
    var flow: NEPacketTunnelFlow? = nil
    var packetBuffer: [NEPacket] = []

    public init()
    {
    }

    // Public functions
    public func name() -> String
    {
        return NetworkExtensionModule.name
    }

    public func handleEffect(_ effect: Effect, _ channel: BlockingQueue<Event>) -> Event?
    {
        switch effect
        {
            case let startTunnelRequest as StartTunnelRequest:
                return startTunnelRequestHandler(startTunnelRequest)

            case let stopTunnelRequest as StopTunnelRequest:
                return stopTunnelRequestHandler(stopTunnelRequest)

            case let appMessageRequest as AppMessageRequest:
                return appMessageRequestHandler(appMessageRequest)

            case let readPacketRequest as ReadPacketRequest:
                return readPacket(readPacketRequest)

            case let writePacketRequest as WritePacketRequest:
                return writePacket(writePacketRequest)

            default:
                print("Unknown effect \(effect)")
                return Failure(effect.id)
        }
    }

    public func handleExternalEvent(_ event: Event)
    {
        return
    }

    public func setConfiguration(_ configuration: NETunnelProviderProtocol)
    {
        self.configuration = configuration
    }

    public func setFlow(_ flow: NEPacketTunnelFlow)
    {
        self.flow = flow
    }

    public func startTunnel(events: BlockingQueue<Event>, options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
    {
        let event = StartTunnelEvent(options: options)
        events.enqueue(element: event)

        let response = startTunnelQueue.dequeue()
        completionHandler(response)
    }

    public func stopTunnel(events: BlockingQueue<Event>, reason: NEProviderStopReason, completionHandler: @escaping () -> Void )
    {
        let event = StopTunnelEvent(reason)
        events.enqueue(element: event)

        self.stopTunnelLock.wait()
        completionHandler()
    }

    public func handleAppMessage(events: BlockingQueue<Event>, data: Data, completionHandler: @escaping (Data?) -> Void)
    {
        let event = AppMessageEvent(data)
        events.enqueue(element: event)

        let response = appMessageQueue.dequeue()
        completionHandler(response)
    }

    // Private functions
    func startTunnelRequestHandler(_ effect: StartTunnelRequest) -> Event?
    {
        startTunnelQueue.enqueue(element: effect.maybeError)
        return StartTunnelResponse(effect.id)
    }

    func stopTunnelRequestHandler(_ effect: StopTunnelRequest) -> Event?
    {
        stopTunnelLock.signal()
        return StopTunnelResponse(effect.id)
    }

    func appMessageRequestHandler(_ effect: AppMessageRequest) -> Event?
    {
        appMessageQueue.enqueue(element: effect.data)
        return AppMessageResponse(effect.id)
    }

    func readPacket(_ effect: ReadPacketRequest) -> Event?
    {
        if self.packetBuffer.isEmpty
        {
            guard let flow = self.flow else
            {
                return Failure(effect.id)
            }

            var packets: [NEPacket] = Synchronizer.sync(flow.readPacketObjects)
            if packets.isEmpty
            {
                return Failure(effect.id)
            }

            let packet = packets[0]
            packets = [NEPacket](packets[1...])

            self.packetBuffer.append(contentsOf: packets)

            return ReadPacketResponse(effect.id, packet.data) // FIXME - support IPv6
        }
        else
        {
            let packet = self.packetBuffer[0]
            self.packetBuffer = [NEPacket](self.packetBuffer[1...])

            return ReadPacketResponse(effect.id, packet.data)
        }
    }

    func writePacket(_ effect: WritePacketRequest) -> Event?
    {
        guard let flow = self.flow else
        {
            return Failure(effect.id)
        }

        let packet = NEPacket(data: effect.data, protocolFamily: 4) // FIXME - support IPv6
        flow.writePacketObjects([packet])

        return WritePacketResponse(effect.id)
    }
}
