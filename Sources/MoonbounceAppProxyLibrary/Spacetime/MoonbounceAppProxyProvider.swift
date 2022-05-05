//
//  MoonbounceAppProxyProvider.swift
//  MoonbounceNetworkExtension
//
//  Created by Adelita Schule on 1/3/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Flower
import LoggerQueue
import Logging
import NetworkExtension
import Simulation
import Spacetime
import SwiftQueue
import Transmission
import Universe

open class MoonbounceAppProxyProvider: NEAppProxyProvider
{
    let apModule: AppProxyModule
    let simulation: Simulation
    let universe: MoonbounceAppProxyUniverse
    let loggerLabel = "org.OperatorFoundation.Moonbounce.MacOS.NetworkExtension"
    var logQueue: LoggerQueue
    var log: Logger!

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

        self.apModule = AppProxyModule()
        self.simulation = Simulation(capabilities: Capabilities(BuiltinModuleNames.networkConnect.rawValue, AppProxyModule.name), userModules: [apModule])
        self.universe = MoonbounceAppProxyUniverse(effects: self.simulation.effects, events: self.simulation.events, logger: self.log, logQueue: self.logQueue)

        super.init()
    }

    override open func startProxy(options: [String : Any]? = nil) async throws
    {
        try self.universe.startProxy(options: options)
    }

    override open func stopProxy(with reason: NEProviderStopReason) async
    {
        self.universe.stopProxy(with: reason)
    }

    override open func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool
    {
        // FIXME
        return false
    }

    override open func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteEndpoint remoteEndpoint: NWEndpoint) -> Bool
    {
        // FIXME
        return false
    }

    override open func sleep(completionHandler: @escaping () -> Void)
    {
        // Add code here to get ready to sleep.
        completionHandler()
    }

    override open func wake()
    {
        // Add code here to wake up.
    }
}
