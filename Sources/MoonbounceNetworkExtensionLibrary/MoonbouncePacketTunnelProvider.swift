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

    private var networkMonitor: NWPathMonitor?
    
    private var ifname: String?
        
    /// The tunnel connection.
    var replicantConnection: Transmission.Connection?
    open var flowerConnection: FlowerConnection?
    
    /// The single logical flow of packets through the tunnel.
    var tunnelConnection: ClientTunnelConnection?
    
    /// The completion handler to call when the tunnel is fully established.
    var pendingStartCompletion: ((Error?) -> Void)?
    
    /// The completion handler to call when the tunnel is fully disconnected.
    var pendingStopCompletion: (() -> Void)?
    
    /// The last error that occurred on the tunnel.
    var lastError: Error?
    
    /// To make sure that we don't try connecting repeatedly and unintentionally
    var connectionAttemptStatus: ConnectionAttemptStatus = .initialized
    
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
        self.simulation = Simulation(capabilities: Capabilities(BuiltinModuleNames.display.rawValue, NetworkExtensionModule.name), userModules: [neModule])
        self.universe = MoonbounceNetworkExtensionUniverse(effects: self.simulation.effects, events: self.simulation.events, logger: self.log, logQueue: self.logQueue)

        super.init()
    }
    
    deinit
    {
        networkMonitor?.cancel()
    }

    public override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void)
    {
        self.neModule.startTunnel(events: self.simulation.events, options: options, completionHandler: completionHandler)
    }


    public override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
    {
        self.neModule.stopTunnel(events: self.simulation.events, reason: reason, completionHandler: completionHandler)
    }
    
    func writePackets(packetDatas: [Data], protocolNumbers: [NSNumber])
    {
        log.debug("Writing packets.")
        self.packets.writePackets(packetDatas, withProtocols: protocolNumbers)
    }
    
    /// Handle IPC messages from the app.
    public override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
        guard let handler = completionHandler else
        {
            return
        }

        self.neModule.handleAppMessage(events: self.simulation.events, data: messageData, completionHandler: handler)
    }
    
    open func closeTunnelWithError(_ error: Error?)
    {
        log.error("Closing the tunnel with error: \(String(describing: error))")
        lastError = error
        pendingStartCompletion?(error)
        
        // Close the tunnel connection.
//        if let replicantConnection = self.replicantConnection
//        {
//            // FIXME: make transmission connection cancellable
//            // replicantConnection.cancel()
//        }
        
        tunnelConnection = nil
        connectionAttemptStatus = .initialized
    }
    
    /// Handle the event of the tunnel connection being closed.
    func tunnelDidClose()
    {
        if pendingStartCompletion != nil
        {
            // Closed while starting, call the start completion handler with the appropriate error.
            pendingStartCompletion?(lastError)
            pendingStartCompletion = nil
        }
        else if pendingStopCompletion != nil
        {
            // Closed as the result of a call to stopTunnelWithReason, call the stop completion handler.
            pendingStopCompletion?()
            pendingStopCompletion = nil
        }
        else
        {
            // Closed as the result of an error on the tunnel connection, cancel the tunnel.
            cancelTunnelWithError(lastError)
        }
    }
    
    // MARK: - ClientTunnelConnection
    
    /// Handle the event of the logical flow of packets being established through the tunnel.
    func setTunnelSettings(tunnelAddress: TunnelAddress)
    {
        log.debug("5. 🚀 setTunnelSettings  🚀")
        
        guard let host = remoteHost
        else
        {
            log.error("Unable to set network settings remote host is nil.")
            connectionAttemptStatus = .initialized
            pendingStartCompletion?(TunnelError.internalError)
            pendingStartCompletion = nil
            return
        }
        
        connectionAttemptStatus = .ipAssigned(tunnelAddress)
        
        let settings = makeNetworkSettings(host: host, tunnelAddress: tunnelAddress)
        log.debug("(setTunnelSettings) host: \(host), tunnelAddress: \(tunnelAddress)")
        
        // Set the virtual interface settings.
        self.setNetworkSettings(settings, completionHandler: tunnelSettingsCompleted)
    }
    
    func tunnelSettingsCompleted(maybeError: Error?)
    {
        log.debug("6. Tunnel settings updated.")
        
        if let error = maybeError
        {
            self.log.error("Failed to set the tunnel network settings: \(error)")
            failedConnection(error: error)
            return
        }

        guard let startCompletion = pendingStartCompletion
        else
        {
            failedConnection(error: TunnelError.internalError)
            return
        }
        
        connectionAttemptStatus = .ready
        startCompletion(nil)
        
        let newConnection = ClientTunnelConnection(clientPacketFlow: self.packets, flowerConnection: self.flowerConnection!, logger: log)

        self.log.debug("\n🚀 Connection to server complete! 🚀\n")
        self.tunnelConnection = newConnection
        newConnection.startHandlingPackets()
    }
    
    func waitForIPAssignment()
    {
        log.debug("Waiting for IP assignment")
        guard let flowerConnection = self.flowerConnection else
        {
            log.error("🛑 Current connection is nil, giving up. 🛑")
            failedConnection(error: TunnelError.disconnected)
            return
        }

        var waiting = true
        while waiting
        {
            log.debug("calling flowerConnection.readMessage()")
            let message = flowerConnection.readMessage()
            log.debug("finished calling flowerConnection.readMessage()")

            switch message
            {
                case .IPAssignV4(let ipv4Address):
                    waiting = false
                    self.setTunnelSettings(tunnelAddress: .ipV4(ipv4Address))
                    print("IPV4 Address: ")
                    print(ipv4Address)
                    return
                case .IPAssignV6(let ipv6Address):
                    waiting = false
                    self.setTunnelSettings(tunnelAddress: .ipV6(ipv6Address))
                    print("IPV6 Address: ")
                    print(ipv6Address)
                    return
                case .IPAssignDualStack(let ipv4Address, let ipv6Address):
                    waiting = false
                    self.setTunnelSettings(tunnelAddress: .dualStack(ipv4Address, ipv6Address))
                    print("IPV4 Address: ")
                    print(ipv4Address)
                    print("IPV6 Address: ")
                    print(ipv6Address)
                    return
                default:
                    waiting = true
            }
        }
    }
        
    func failedConnection(error: Error)
    {
        connectionAttemptStatus = .failed
        
        if let completionHandler = pendingStartCompletion
        {
            completionHandler(error)
            pendingStartCompletion = nil
        }
    }
}

enum ConnectionAttemptStatus
{
    case initialized // Start tunnel has not been called yet
    case started // Start tunnel has been called but nothing has been done yet
    case connecting // Tried to connect to the server but have not heard back yet
    case connected // Connected to the server
    case ipAssigned(TunnelAddress) // Received an IP assignment message from the server
    case ready // Connected and able to received packets (handshakes etc. are complete)
    case stillReady // ??
    case failed // Failed :(
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
