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
}
