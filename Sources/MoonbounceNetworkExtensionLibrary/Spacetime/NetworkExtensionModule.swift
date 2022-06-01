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
    var provider: NEPacketTunnelProvider? = nil
    public var connections: [UUID: NWTCPConnectConnection] = [:]

    let startTunnelDispatchQueue = DispatchQueue(label: "StartTunnel")
    let stopTunnelDispatchQueue = DispatchQueue(label: "StopTunnel")
    let handleAppMessageDispatchQueue = DispatchQueue(label: "HandleAppMessage")

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

            case let setNetworkTunnelSettingsRequest as SetNetworkTunnelSettingsRequest:
                return setNetworkTunnelSettings(setNetworkTunnelSettingsRequest)

            case let connectRequest as NWTCPConnectRequest:
                return connect(connectRequest)

            case let writeRequest as NWTCPWriteRequest:
                return write(writeRequest)

            case let readRequest as NWTCPReadRequest:
                return read(readRequest)

            case let closeRequest as NWTCPCloseRequest:
                return close(closeRequest)

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

    public func setProvider(_ provider: NEPacketTunnelProvider)
    {
        self.provider = provider
    }

    public func setFlow(_ flow: NEPacketTunnelFlow)
    {
        self.flow = flow
    }

    public func startTunnel(events: BlockingQueue<Event>, options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
    {
        self.startTunnelDispatchQueue.async
        {
            let event = StartTunnelEvent(options: options)
            events.enqueue(element: event)

            let response = self.startTunnelQueue.dequeue()
            completionHandler(response)
        }
    }

    public func stopTunnel(events: BlockingQueue<Event>, reason: NEProviderStopReason, completionHandler: @escaping () -> Void )
    {
        self.stopTunnelDispatchQueue.async
        {
            let event = StopTunnelEvent(reason)
            events.enqueue(element: event)

            self.stopTunnelLock.wait()
            completionHandler()
        }
    }

    public func handleAppMessage(events: BlockingQueue<Event>, data: Data, completionHandler: ((Data?) -> Void)?)
    {
        self.handleAppMessageDispatchQueue.async
        {
            let event = AppMessageEvent(data)
            events.enqueue(element: event)

            let response = self.appMessageQueue.dequeue()
            if let handler = completionHandler
            {
                handler(response)
            }
        }
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

    func setNetworkTunnelSettings(_ effect: SetNetworkTunnelSettingsRequest) -> Event?
    {
        guard let provider = self.provider else
        {
            return Failure(effect.id)
        }

        let settings = self.makeNetworkSettings(host: effect.host, tunnelAddress: effect.tunnelAddress)

        let maybeError = Synchronizer.sync
        {
            (completionHandler: @escaping (Error?) -> Void) in

            provider.setNetworkSettings(settings, completionHandler: completionHandler)
        }

        if maybeError != nil
        {
            return Failure(effect.id)
        }
        else
        {
            return SetNetworkTunnelSettingsResponse(effect.id)
        }
    }

    func connect(_ effect: NWTCPConnectRequest) -> Event?
    {
        guard let provider = self.provider else
        {
            return Failure(effect.id)
        }

        let uuid = UUID()

        let endpoint = NWHostEndpoint(hostname: effect.host, port: effect.port.string)
        let connection = provider.createTCPConnection(to: endpoint, enableTLS: false, tlsParameters: nil, delegate: nil)
        // FIXME
//        self.connections[endpoint] = connection
        return nil
    }

    func read(_ effect: NWTCPReadRequest) -> Event?
    {
        // FIXME
        return nil
    }

    func write(_ effect: NWTCPWriteRequest) -> Event?
    {
        // FIXME
        return nil
    }

    func close(_ effect: NWTCPCloseRequest) -> Event?
    {
        // FIXME
        return nil
    }

    /// host must be an ipv4 address and port "ipAddress:port". For example: "127.0.0.1:1234".
    func makeNetworkSettings(host: String, tunnelAddress: TunnelAddress) -> NEPacketTunnelNetworkSettings?
    {
        let googleDNSipv4 = "8.8.8.8"
        let googleDNS2ipv4 = "8.8.4.4"
        let googleDNSipv6 = "2001:4860:4860::8888"
        let googleDNS2ipv6 = "2001:4860:4860::8844"
        let tunIPSubnetMask = "255.255.255.255"
//        let tunIPv6RouteAddress = ""

        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: host)

        // These are the Google DNS Settings, we will use these for now
        let dnsServerStrings = [googleDNSipv4, googleDNS2ipv4, googleDNSipv6, googleDNS2ipv6]
        let dnsSettings = NEDNSSettings(servers: dnsServerStrings)
        // dnsSettings.matchDomains = [""] // All DNS queries must first go through the tunnel's DNS
        networkSettings.dnsSettings = dnsSettings

        switch tunnelAddress
        {
            case .ipV4(let tunIPv4Address):
                let ipv4Settings = NEIPv4Settings(addresses: ["\(tunIPv4Address)"], subnetMasks: [tunIPSubnetMask])
                // No routes specified, use the default route.
                ipv4Settings.includedRoutes = [NEIPv4Route.default()]
                networkSettings.ipv4Settings = ipv4Settings
            case .ipV6(let tunIPv6Address):
                let ipv6Settings = NEIPv6Settings(addresses: ["\(tunIPv6Address)"], networkPrefixLengths: [64])
                ipv6Settings.includedRoutes = [NEIPv6Route.default()]
                networkSettings.ipv6Settings = ipv6Settings
            case .dualStack(let tunIPv4Address, let tunIPv6Address):
                // IPv4
                let ipv4Settings = NEIPv4Settings(addresses: ["\(tunIPv4Address)"], subnetMasks: [tunIPSubnetMask])
                // No routes specified, use the default route.
                ipv4Settings.includedRoutes = [NEIPv4Route.default()]
                networkSettings.ipv4Settings = ipv4Settings

                // IPv6
                let ipv6Settings = NEIPv6Settings(addresses: ["\(tunIPv6Address)"], networkPrefixLengths: [64])
                ipv6Settings.includedRoutes = [NEIPv6Route.default()]
                networkSettings.ipv6Settings = ipv6Settings
        }

        // FIXME: These should be set later when we have a ReplicantConnection
        //    // This should be derived from the specific polish specified by the replicant config
        //    networkSettings.tunnelOverheadBytes = 0
        //
        //    if let polish = replicantConfig.polish as? SilverClientConfig
        //    {
        //        networkSettings.mtu = NSNumber(value: polish.chunkSize)
        //    }

        return networkSettings
    }

}
