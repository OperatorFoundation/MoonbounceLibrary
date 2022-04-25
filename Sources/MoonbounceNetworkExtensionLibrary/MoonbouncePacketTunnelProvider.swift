//
//  PacketTunnelProvider.swift
//  MoonbounceNetworkExtension
//
//  Created by Adelita Schule on 1/3/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Flower
import LoggerQueue
import Logging
import Net
import NetworkExtension
//import ReplicantSwift
//import ReplicantSwiftClient
import Simulation
import Spacetime
import SwiftQueue
import Transmission
import Universe

open class MoonbouncePacketTunnelProvider: NEPacketTunnelProvider
{
    let neModule: NetworkExtensionModule
    let simulation: Simulation
    let universe: MoonbounceNetworkExtensionUniverse
    let loggerLabel = "org.OperatorFoundation.Moonbounce.MacOS.NetworkExtension"
    var logQueue: LoggerQueue
    var log: Logger!

    /// The tunnel connection.
    var replicantConnection: Transmission.Connection?
    open var flowerConnection: FlowerConnection?
    
    /// The address of the tunnel server.
    open var remoteHost: String?

    public override init()
    {
        let logQueue = LoggerQueue(label: self.loggerLabel)
        self.logQueue = logQueue

        LoggingSystem.bootstrap
        {
            (label) in

            logQueue.queue.enqueue(LoggerQueueMessage(message: "Bootstrap closure."))
            return logQueue
        }

        self.log = Logger(label: self.loggerLabel)
        self.log.logLevel = .debug
        self.logQueue.queue.enqueue(LoggerQueueMessage(message: "Initialized PacketTunnelProvider"))

        self.neModule = NetworkExtensionModule()
        self.simulation = Simulation(capabilities: Capabilities(BuiltinModuleNames.networkConnect.rawValue, NetworkExtensionModule.name), userModules: [neModule])
        self.universe = MoonbounceNetworkExtensionUniverse(effects: self.simulation.effects, events: self.simulation.events, logger: self.log, logQueue: self.logQueue)

        super.init()
    }
    
    public override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void)
    {
        let maybeError = self.universe.startTunnel(options: options)
        completionHandler(maybeError)
    }


    public override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
    {
        self.universe.stopTunnel(with: reason)
    }
    
    /// Handle IPC messages from the app.
    public override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
        let result = self.universe.handleAppMessage(data: messageData)

        if let handler = completionHandler
        {
            handler(result)
            return
        }
    }

    open override func cancelTunnelWithError(_ error: Error?)
    {
        log.error("Closing the tunnel with error: \(String(describing: error))")
        self.stopTunnel(with: NEProviderStopReason.userInitiated)
        {
            return
        }
    }
}

public enum TunnelError: Error
{
    case badConfiguration
    case badConnection
    case cancelled
    case disconnected
    case internalError
}

public enum TunnelAddress
{
    case ipV4(IPv4Address)
    case ipV6(IPv6Address)
    case dualStack(IPv4Address, IPv6Address)
}

enum PacketTunnelProviderError: String, Error
{
    case savedProtocolConfigurationIsInvalid
    case dnsResolutionFailure
    case couldNotStartBackend
    case couldNotDetermineFileDescriptor
    case couldNotSetNetworkSettings
}
