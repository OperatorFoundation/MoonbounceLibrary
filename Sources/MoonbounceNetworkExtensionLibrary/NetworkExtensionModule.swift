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

    // Private functions

    func stopTunnelRequestHandler()
    {
        self.logger.debug("🌐 NetworkExtensionModule: stopTunnelRequestHandler")
        stopTunnelLock.signal()
    }

    public func getTunnelConfiguration() throws -> String
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
        
        return serverAddress
    }

    func readPacket() throws -> NEPacket
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
            return packet
        }
        else
        {
            let packet = self.packetBuffer[0]
            self.packetBuffer = [NEPacket](self.packetBuffer[1...])
            return packet
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

    func setNetworkTunnelSettings(host: String, tunnelAddress: TunnelAddress) async throws
    {
        self.logger.log("🌐 NetworkExtensionModule: setNetworkTunnelSettings")
        
        guard let provider = self.provider else
        {
            throw NEModuleError.providerIsNil
        }

        let settings = self.makeNetworkSettings(host: host, tunnelAddress: tunnelAddress)
        self.logger.log("starting setTunnelNetworkSettings")
        try await provider.setTunnelNetworkSettings(settings)
        self.logger.log("finished setNetworkTunnelSettings")
        self.logger.log("finished setNetworkTunnelSettings sync")
    }

    /// host must be an ipv4 address and port "ipAddress:port". For example: "127.0.0.1:1234".
    func makeNetworkSettings(host: String, tunnelAddress: TunnelAddress) -> NEPacketTunnelNetworkSettings?
    {
        self.logger.log("🌐 NetworkExtensionModule: makeNetworkSettings")
        
        let googleDNSipv4 = "8.8.8.8"
        let googleDNS2ipv4 = "8.8.4.4"
        let googleDNSipv6 = "2001:4860:4860::8888"
        let googleDNS2ipv6 = "2001:4860:4860::8844"
        let tunIPSubnetMask = "0.0.0.0"
//        let tunIPSubnetMask = "255.255.255.255"
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
