//
//  NetworkExtensionModule.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Logging
import NetworkExtension
import os.log

import Chord
import Simulation
import Spacetime

public class NetworkExtensionModule: Module
{
    static public let name = "NetworkExtension"

    var configuration: NEVPNProtocol? = nil
    let startTunnelQueue = BlockingQueue<Error?>()
    let stopTunnelLock = DispatchSemaphore(value: 0)
    let appMessageQueue = BlockingQueue<Data?>()
    var flow: NEPacketTunnelFlow? = nil
    var packetBuffer: [NEPacket] = []
    var provider: NEPacketTunnelProvider? = nil
    public var connections: [UUID: SimulationNWTCPConnection] = [:]
    var logger = Logger(label: "MBLogger.MoonbouceNetworkExtensionLibrary.NetworkExtensionModule")
    
    let startTunnelDispatchQueue = DispatchQueue(label: "StartTunnel")
    let stopTunnelDispatchQueue = DispatchQueue(label: "StopTunnel")
    let handleAppMessageDispatchQueue = DispatchQueue(label: "HandleAppMessage")

    public init()
    {
        self.logger.logLevel = .debug
        self.logger.debug("Initialized NetworkExtensionModule")
    }

    // Public functions
    public func name() -> String
    {
        self.logger.debug("NetworkExtensionModule.name")
        return NetworkExtensionModule.name
    }

    public func handleEffect(_ effect: Effect, _ channel: BlockingQueue<Event>) -> Event?
    {
        os_log("MoonbounceLibrary: NetworkExtensionModule.handleEffect")
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

            case let getConfigurationRequest as GetConfigurationRequest:
                os_log("MoonbounceLibrary: NetworkExtensionModule.handleEffect: received a getConfigurationRequest")
                return getTunnelConfiguration(getConfigurationRequest)

            case let connectRequest as NWTCPConnectRequest:
                return connect(connectRequest)

            case let writeRequest as NWTCPWriteRequest:
                return write(writeRequest, channel)

            case let readRequest as NWTCPReadRequest:
                return read(readRequest, channel)

            case let closeRequest as NWTCPCloseRequest:
                return close(closeRequest, channel)

            default:
                print("NetworkExtensionModule: Unknown effect \(effect)")
                os_log("MoonbounceLibrary: NetworkExtensionModule: Unknown effect \(effect)")
                return Failure(effect.id)
        }
    }

    public func handleExternalEvent(_ event: Event)
    {
        self.logger.debug("NetworkExtensionModule.handleExternalEvent")
        return
    }

    public func setConfiguration(_ configuration: NEVPNProtocol)
    {
        os_log("MoonbounceLibrary: NetworkExtensionModule.setConfiguration")
        self.configuration = configuration
        os_log("MoonbounceLibrary: NetworkExtensionModule.setConfiguration: configuration exists? - \(configuration != nil)")
        os_log("MoonbounceLibrary: NetworkExtensionModule.setConfiguration: self.confguration exists? - \(self.configuration != nil)")
    }

    public func setProvider(_ provider: NEPacketTunnelProvider)
    {
        os_log("MoonbounceLibrary: NetworkExtensionModule.setProvider")
        self.provider = provider
    }

    public func setFlow(_ flow: NEPacketTunnelFlow)
    {
        self.logger.debug("MoonbounceLibrary: NetworkExtensionModule.setFlow")
        self.flow = flow
    }

    public func startTunnel(events: BlockingQueue<Event>, options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
    {
        os_log("MoonbounceLibrary: NetworkExtensionModule.startTunnel")
        self.logger.debug("NetworkExtensionModule.startTunnel")

        self.startTunnelDispatchQueue.async
        {
            let event = StartTunnelEvent(options: options)
            events.enqueue(element: event)

            if let response = self.startTunnelQueue.dequeue() {
                self.logger.debug("failed to start tunnel: \(response)")
                // FIXME: should probably stop the tunnel here
            }
        }
        
        completionHandler(nil)
    }

    public func stopTunnel(events: BlockingQueue<Event>, reason: NEProviderStopReason, completionHandler: @escaping () -> Void )
    {
        self.logger.debug("NetworkExtensionModule.stopTunnel")
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
        self.logger.debug("NetworkExtensionModule.handleAppMessage")
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
        self.logger.debug("NetworkExtensionModule.startTunnelRequestHandler")
        startTunnelQueue.enqueue(element: effect.maybeError)
        return StartTunnelResponse(effect.id)
    }

    func stopTunnelRequestHandler(_ effect: StopTunnelRequest) -> Event?
    {
        self.logger.debug("NetworkExtensionModule.stopTunnelRequestHandler")
        stopTunnelLock.signal()
        return StopTunnelResponse(effect.id)
    }

    public func getTunnelConfiguration(_ effect: GetConfigurationRequest) -> Event?
    {
        os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration")
        os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration: self.confguration - \(self.configuration != nil)")

        if let configuration = self.configuration
        {
            os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration returning self.configuration: \(configuration.description)")
            return GetConfigurationResponse(effect.id, configuration)
        }
        else if let provider = self.provider
        {
            os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration self.provider exists? \(provider != nil)")
            os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration returning self.provider?.protocolConfiguration exists?: \(provider.protocolConfiguration != nil)")
            
            guard let serverAddress = provider.protocolConfiguration.serverAddress else
            {
                os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration failed because serverAddress is nil")
                return Failure(effect.id)
            }
            os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration serverAddress exists? - \(serverAddress != nil)")
            return GetConfigurationResponse(effect.id, provider.protocolConfiguration)
        }
        else
        {
            os_log("MoonbounceLibrary: NetworkExtensionModule.getConfiguration failed because self.configuration is nil? \(self.configuration == nil)")
            return Failure(effect.id)
        }
    }

    func appMessageRequestHandler(_ effect: AppMessageRequest) -> Event?
    {
        self.logger.debug("NetworkExtensionModule.appMessageRequestHandler")
        appMessageQueue.enqueue(element: effect.data)
        return AppMessageResponse(effect.id)
    }

    func readPacket(_ effect: ReadPacketRequest) -> Event?
    {
        self.logger.debug("NetworkExtensionModule.readPacket")
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
        self.logger.debug("NetworkExtensionModule.writePacket")
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
        self.logger.debug("NetworkExtensionModule.setNetworkTunnelSettings")
        guard let provider = self.provider else
        {
            return Failure(effect.id)
        }

        let settings = self.makeNetworkSettings(host: effect.host, tunnelAddress: effect.tunnelAddress)

        let maybeError = Synchronizer.sync
        {
            (completionHandler: @escaping (Error?) -> Void) in
            
            provider.setTunnelNetworkSettings(settings, completionHandler: completionHandler)
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
        self.logger.debug("NetworkExtensionModule: creating a TCP connection to \(effect.host):\(effect.port)")
        os_log("MoonbounceLibrary: NetworkExtensionModule: creating a TCP connection to \(effect.host):\(effect.port)")
        let networkConnection = provider.createTCPConnection(to: endpoint, enableTLS: false, tlsParameters: nil, delegate: nil)
        let transmissionConnection = NWTCPTransmissionConnection(networkConnection)
        let connection = SimulationNWTCPConnection(transmissionConnection)

        self.connections[uuid] = connection

        return NWTCPConnectResponse(effect.id, socketId: uuid)
    }

    func read(_ effect: NWTCPReadRequest, _ channel: BlockingQueue<Event>) -> Event?
    {
        let uuid = effect.socketId
        guard let connection = self.connections[uuid] else
        {
            let failure = Failure(effect.id)
            print(failure.description)
            return failure
        }

        connection.read(request: effect, channel: channel)
        return nil
    }

    func write(_ effect: NWTCPWriteRequest, _ channel: BlockingQueue<Event>) -> Event?
    {
        let uuid = effect.socketId
        guard let connection = self.connections[uuid] else
        {
            let failure = Failure(effect.id)
            print(failure.description)
            return failure
        }

        connection.write(request: effect, channel: channel)
        return nil
    }

    func close(_ effect: NWTCPCloseRequest, _ channel: BlockingQueue<Event>) -> Event?
    {
        let uuid = effect.socketId
        if let connection = self.connections[uuid]
        {
            connection.close(request: effect, state: self, channel: channel)
            return nil
        }
        else
        {
            let failure = Failure(effect.id)
            print(failure.description)
            return failure
        }
    }

    /// host must be an ipv4 address and port "ipAddress:port". For example: "127.0.0.1:1234".
    func makeNetworkSettings(host: String, tunnelAddress: TunnelAddress) -> NEPacketTunnelNetworkSettings?
    {
        self.logger.debug("NetworkExtensionModule.makeNetworkSettings")
        
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
