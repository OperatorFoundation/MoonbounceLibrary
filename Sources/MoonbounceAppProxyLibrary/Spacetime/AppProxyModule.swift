//
//  AppProxyModule.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Chord
import Foundation
import NetworkExtension
import Simulation
import Spacetime

public class AppProxyModule: Module
{
    static public let name = "AppProxy"

    let tcpFlows: [UUID: NEAppProxyFlow] = [:]
    let udpFlows: [UUID: NEAppProxyUDPFlow] = [:]

    let startProxyQueue = BlockingQueue<Error?>()
    let stopProxyLock = DispatchSemaphore(value: 0)
    let handleNewFlowQueue = BlockingQueue<Bool>()
    let handleNewUdpFlowQueue = BlockingQueue<Bool>()
    let appMessageQueue = BlockingQueue<Data?>()
    var packetBuffer: [NEPacket] = []

    let startProxyDispatchQueue = DispatchQueue(label: "StartProxy")
    let stopProxyDispatchQueue = DispatchQueue(label: "StopProxy")
    let handleAppMessageDispatchQueue = DispatchQueue(label: "HandleAppMessage")

    public init()
    {
    }

    // Public functions
    public func name() -> String
    {
        return AppProxyModule.name
    }

    public func handleEffect(_ effect: Effect, _ channel: BlockingQueue<Event>) -> Event?
    {
        switch effect
        {
            case let startProxyRequest as StartProxyRequest:
                return startProxyRequestHandler(startProxyRequest)

            case let stopProxyRequest as StopProxyRequest:
                return stopProxyRequestHandler(stopProxyRequest)

            case let appMessageRequest as AppMessageRequest:
                return appMessageRequestHandler(appMessageRequest)

//            case let setNetworkTunnelSettingsRequest as SetNetworkTunnelSettingsRequest:
//                return setNetworkTunnelSettings(setNetworkTunnelSettingsRequest)

            default:
                print("Unknown effect \(effect)")
                return Failure(effect.id)
        }
    }

    public func handleExternalEvent(_ event: Event)
    {
        return
    }

    public func startProxy(_ events: BlockingQueue<Event>, options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
    {
        self.startProxyDispatchQueue.async
        {
            let event = StartProxyEvent(options: options)
            events.enqueue(element: event)

            let response = self.startProxyQueue.dequeue()
            completionHandler(response)
        }
    }

    public func stopProxy(_ events: BlockingQueue<Event>, reason: NEProviderStopReason, completionHandler: @escaping () -> Void )
    {
        self.stopProxyDispatchQueue.async
        {
            let event = StopProxyEvent(reason)
            events.enqueue(element: event)

            self.stopProxyLock.wait()
            completionHandler()
        }
    }

    public func handleAppMessage(_ events: BlockingQueue<Event>, data: Data, completionHandler: @escaping (Data?) -> Void)
    {
        self.handleAppMessageDispatchQueue.async
        {
            let event = AppMessageEvent(data)
            events.enqueue(element: event)

            let response = self.appMessageQueue.dequeue()
            completionHandler(response)
        }
    }

    public func handleNewFlow(_ events: BlockingQueue<Event>, _ flow: NEAppProxyFlow) -> Bool
    {
        let uuid = UUID()

        let event = NewTcpFlowEvent(uuid: uuid)
        events.enqueue(element: event)

        let response = self.handleNewFlowQueue.dequeue()
        return response
    }

    public func handleNewUDPFlow(_ events: BlockingQueue<Event>, _ flow: NEAppProxyUDPFlow, initialRemoteEndpoint remoteEndpoint: NWEndpoint) -> Bool
    {
        let uuid = UUID()

        let event = NewUdpFlowEvent(uuid: uuid)
        events.enqueue(element: event)

        let response = self.handleNewUdpFlowQueue.dequeue()
        return response
    }

    // Private functions
    func startProxyRequestHandler(_ effect: StartProxyRequest) -> Event?
    {
        startProxyQueue.enqueue(element: effect.maybeError)
        return StartProxyResponse(effect.id)
    }

    func stopProxyRequestHandler(_ effect: StopProxyRequest) -> Event?
    {
        stopProxyLock.signal()
        return StopProxyResponse(effect.id)
    }

    func appMessageRequestHandler(_ effect: AppMessageRequest) -> Event?
    {
        appMessageQueue.enqueue(element: effect.data)
        return AppMessageResponse(effect.id)
    }
}
