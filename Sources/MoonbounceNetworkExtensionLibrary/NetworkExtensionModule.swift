//
//  NetworkExtensionModule.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Chord

public class NetworkExtensionModule
{
    static public let name = "NetworkExtension"

    var configuration: NEVPNProtocol? = nil
    let startTunnelQueue = BlockingQueue<String?>()
    let stopTunnelLock = DispatchSemaphore(value: 0)
    let appMessageQueue = BlockingQueue<Data?>()
    var flow: NEPacketTunnelFlow? = nil
    var packetBuffer: [NEPacket] = []
    var provider: NEPacketTunnelProvider? = nil
    public var connections: [UUID: SimulationNWTCPConnection] = [:]
    var logger: Logger
    
    let startTunnelDispatchQueue = DispatchQueue(label: "StartTunnel")
    let stopTunnelDispatchQueue = DispatchQueue(label: "StopTunnel")
    let handleAppMessageDispatchQueue = DispatchQueue(label: "HandleAppMessage")

    public init(logger: Logger)
    {
        self.logger = logger
        self.logger.log("🌐 NetworkExtensionModule: Initialized")
    }
    
    public func setLogger(logger: Logger?)
    {
        if let newLogger = logger
        {
            self.logger = newLogger
        }
    }
    
    // Public functions
    public func name() -> String
    {
        return NetworkExtensionModule.name
    }

    public func setConfiguration(_ configuration: NEVPNProtocol)
    {
        self.configuration = configuration
        logger.log("🌐 NetworkExtensionModule: setConfiguration: configuration - \(configuration.debugDescription)")
    }

    public func setProvider(_ provider: NEPacketTunnelProvider)
    {
        self.provider = provider
    }

    public func setFlow(_ flow: NEPacketTunnelFlow)
    {
        self.flow = flow
    }

    public func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
    {
        logger.log("🌐 NetworkExtensionModule: startTunnel")

        if let options
        {
            print("WARNING: Ignoring options \(options)")
        }

        self.startTunnelDispatchQueue.async
        {

            if let response = self.startTunnelQueue.dequeue()
            {
                self.logger.debug("🌐 failed to start tunnel: \(response.debugDescription)")
                // FIXME: should probably stop the tunnel here
            }
        }
        
        completionHandler(nil)
    }

    public func stopTunnel(reason: NEProviderStopReason, completionHandler: @escaping () -> Void )
    {
        self.logger.debug("🌐 NetworkExtensionModule: stopTunnel")
        self.stopTunnelDispatchQueue.async
        {
            self.stopTunnelLock.wait()
            completionHandler()
        }
    }

    public func handleAppMessage(data: Data, completionHandler: ((Data?) -> Void)?)
    {
        self.logger.debug("🌐 NetworkExtensionModule: handleAppMessage")
        self.handleAppMessageDispatchQueue.async
        {
            let response = self.appMessageQueue.dequeue()
            if let handler = completionHandler
            {
                handler(response)
            }
        }
    }

    // Private functions

    func stopTunnelRequestHandler()
    {
        self.logger.debug("🌐 NetworkExtensionModule: stopTunnelRequestHandler")
        stopTunnelLock.signal()
    }

    public func getTunnelConfiguration() throws
    {
        guard let provider = self.provider else
        {
            logger.log("🌐 NetworkExtensionModule: getTunnelConfiguration failure, provider is nil")
            throw NEModuleError.providerIsNil
        }

        guard let serverAddress = provider.protocolConfiguration.serverAddress else
        {
            logger.log("🌐 NetworkExtensionModule: getTunnelConfiguration failure, server address is nil")
            throw NEModuleError.serverAddressIsNil
        }

        logger.log("🌐 NetworkExtensionModule: getConfiguration returning serverAddress: \(serverAddress.description)")
    }

    func readPacket() throws
    {
        self.logger.log("🌐 NetworkExtensionModule: readPacket")
        
        if self.packetBuffer.isEmpty
        {
            guard let flow = self.flow else
            {
                throw NEModuleError.nePacketTunnelFlowIsNil
            }

            var packets: [NEPacket] = Synchronizer.sync(flow.readPacketObjects)
            if packets.isEmpty
            {
                // throw
            }

            let packet = packets[0]
            packets = [NEPacket](packets[1...])

            self.packetBuffer.append(contentsOf: packets)
        }
        else
        {
            let packet = self.packetBuffer[0]
            self.packetBuffer = [NEPacket](self.packetBuffer[1...])
        }
    }

    func writePacket(data: Data) throws
    {
        self.logger.log("🌐 NetworkExtensionModule: writePacket")
        guard let flow = self.flow else
        {
            throw NEModuleError.nePacketTunnelFlowIsNil
        }

        let packet = NEPacket(data: data, protocolFamily: 4) // FIXME - support IPv6
        flow.writePacketObjects([packet])
    }

    func setNetworkTunnelSettings(host: String, tunnelAddress: TunnelAddress) throws
    {
        self.logger.log("🌐 NetworkExtensionModule: setNetworkTunnelSettings")
        
        guard let provider = self.provider else
        {
            throw NEModuleError.providerIsNil
        }

        let settings = self.makeNetworkSettings(host: host, tunnelAddress: tunnelAddress)

        let maybeError = Synchronizer.sync
        {
            (completionHandler: @escaping (Error?) -> Void) in
            
            provider.setTunnelNetworkSettings(settings, completionHandler: completionHandler)
        }

        if let error = maybeError
        {
            throw error
        }
    }

    func connect(host: String, port: String) throws
    {
        guard let provider = self.provider else
        {
            throw NEModuleError.providerIsNil
        }

        let uuid = UUID()
        let endpoint = NWHostEndpoint(hostname: host, port: port)
        self.logger.log("🌐 NetworkExtensionModule: creating a TCP connection to \(host):\(port)")
        self.logger.log("🌐 NetworkExtensionModule.connect() endpoint: \(endpoint)")
        
        let networkConnection = provider.createTCPConnection(to: endpoint, enableTLS: false, tlsParameters: nil, delegate: nil)
        
        guard let transmissionConnection = NWTCPTransmissionConnection(networkConnection, logger: self.logger) else
        {
            self.logger.log("🛑 NetworkExtensionModule: failed to create an NWTCPTransmissionConnection")
            throw NEModuleError.connectionFailure
        }
        
        let connection = SimulationNWTCPConnection(transmissionConnection, logger: logger)
        self.connections[uuid] = connection
    }

    func read(uuid: UUID, size: Int) throws -> Data
    {
        self.logger.log("🌐 NetworkExtensionModule: read()")
        
        guard let connection = self.connections[uuid] else
        {
            logger.log("🛑 NetworkExtensionModule: NWTCPReadRequest failed")
            throw NEModuleError.connectionFailure
        }

        guard let readResult = connection.networkConnection.read(size: size) else
        {
            throw NEModuleError.readFailed
        }
        
        return readResult
    }

    func write(uuid: UUID, data: Data) throws -> Bool
    {
        self.logger.log("🌐 NetworkExtensionModule: write()")
        
        guard let connection = self.connections[uuid] else
        {
            logger.log("🛑 NetworkExtensionModule: NWTCPWriteRequest failed")
            throw NEModuleError.connectionFailure
        }

        return connection.networkConnection.write(data: data)
    }

    func close(uuid: UUID) throws
    {
        self.logger.log("🌐 NetworkExtensionModule: close()")
        if let connection = self.connections[uuid]
        {
            connection.networkConnection.close()
        }
        else
        {
            throw NEModuleError.connectionFailure
        }
    }

    /// host must be an ipv4 address and port "ipAddress:port". For example: "127.0.0.1:1234".
    func makeNetworkSettings(host: String, tunnelAddress: TunnelAddress) -> NEPacketTunnelNetworkSettings?
    {
        self.logger.log("🌐 NetworkExtensionModule: makeNetworkSettings")
        
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

public enum NEModuleError: Error {
    case providerIsNil
    case serverAddressIsNil
    case nePacketTunnelFlowIsNil
    case connectionFailure
    case readFailed
}
