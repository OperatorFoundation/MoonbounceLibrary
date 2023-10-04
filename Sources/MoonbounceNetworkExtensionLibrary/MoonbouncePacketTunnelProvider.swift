//
//  PacketTunnelProvider.swift
//  MoonbounceNetworkExtension
//
//  Created by Adelita Schule on 1/3/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Net
import NetworkExtension
import os.log

import SwiftQueue
import Transmission

open class MoonbouncePacketTunnelProvider: NEPacketTunnelProvider
{
    let neModule: NetworkExtensionModule
    var logger = Logger(subsystem: "org.OperatorFoundation.MoonbounceLogger", category: "NetworkExtension")

    /// The tunnel connection.
    var replicantConnection: Transmission.Connection?
    
    /// The address of the tunnel server.
    open var remoteHost: String?

    public override init()
    {
        self.logger.log("MoonbouncePacketTunnelProvider: init")
        
        self.neModule = NetworkExtensionModule(logger: self.logger)

        super.init()

        self.neModule.setProvider(self)
        self.neModule.setConfiguration(self.protocolConfiguration)
        self.logger.log("MoonbouncePacketTunnelProvider: Initialization complete")
    }

    // NEPacketTunnelProvider
    public override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void)
    {
        self.logger.log("MoonbouncePacketTunnelProvider: startTunnel")
        self.neModule.setConfiguration(self.protocolConfiguration)
        self.neModule.startTunnel(options: options, completionHandler: completionHandler)
    }


    public override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
    {
        self.logger.log("MoonbouncePacketTunnelProvider: stopTunnel")
        self.neModule.stopTunnel(reason: reason, completionHandler: completionHandler)
    }
    
    /// Handle IPC messages from the app.
    public override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
        self.logger.debug("MoonbouncePacketTunnelProvider: handleAppMessage")
        self.neModule.handleAppMessage(data: messageData, completionHandler: completionHandler)
    }

    open override func cancelTunnelWithError(_ error: Error?)
    {
        self.logger.debug("MoonbouncePacketTunnelProvider: cancelTunnelWithError")
        logger.error("MoonbouncePacketTunnelProvider: Closing the tunnel with error: \(String(describing: error))")
        self.stopTunnel(with: NEProviderStopReason.userInitiated)
        {
            return
        }
    }
    // End NEPacketTunnelProvider
}

public enum TunnelError: Error
{
    case badConfiguration
    case badConnection
    case cancelled
    case disconnected
    case internalError
}

public enum TunnelAddress: Codable
{
    case ipV4(IPv4Address)
    case ipV6(IPv6Address)
    case dualStack(IPv4Address, IPv6Address)
    
    var description: String
    {
        switch self
        {
            case .ipV4(let address):
                return address.debugDescription
            case .ipV6(let address):
                return address.debugDescription
            case .dualStack(let ipv4, let ipv6):
                return "ipv4: \(ipv4.debugDescription), ipv6: \(ipv6.debugDescription)"
        }
    }
}

enum PacketTunnelProviderError: String, Error
{
    case savedProtocolConfigurationIsInvalid
    case dnsResolutionFailure
    case couldNotStartBackend
    case couldNotDetermineFileDescriptor
    case couldNotSetNetworkSettings
}
