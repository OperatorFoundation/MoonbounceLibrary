//
//  AppProxyNetworkExtension.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/5/22.
//

import Foundation
import Logging
import NetworkExtension

import Flower
import LoggerQueue
import Simulation
import Spacetime
import Transmission
import Universe

public class AppProxyNetworkExtension: MoonbounceAppProxyUniverse
{
    override public func startProxy(options: [String: Any]?) throws
    {
        appLog.debug("1. 👾 PacketProxyProvider startProxy called 👾")

        //        guard let moonbounceConfig = NetworkExtensionConfigController.getMoonbounceConfig(fromProtocolConfiguration: configuration) else
        //        {
        //            appLog.error("Unable to get moonbounce config from protocol.")
        //            return PacketProxyProviderError.savedProtocolConfigurationIsInvalid
        //        }

        //        guard let replicantConfig = moonbounceConfig.replicantConfig
        //            else
        //        {
        //            self.log.debug("start proxy failed to find a replicant configuration")
        //            completionHandler(ProxyError.badConfiguration)
        //            return
        //        }

        //        let host = moonbounceConfig.replicantConfig?.serverIP
        //        let port = moonbounceConfig.replicantConfig?.port

        let host = "128.199.9.9"
        let port = 80

        self.appLog.debug("\nReplicant Connection Factory Created.\nHost - \(host)\nPort - \(port)\n")

        appLog.debug("2. Connect to server called.")

        //        guard let replicantConnection = ReplicantConnection(type: ConnectionType.tcp, config: replicantConfig, logger: log) else {
        //            log.error("could not initialize replicant connection")
        //            return
        //        }

        guard let replicantConnection = TransmissionConnection(host: host, port: port) else
        {
            appLog.error("could not initialize replicant connection")
            throw MoonbounceUniverseError.connectionFailed
        }
        self.network = replicantConnection
        self.flower = FlowerConnection(connection: replicantConnection)

        self.appLog.debug("\n3. 🌲 Connection state is ready 🌲\n")
        self.appLog.debug("Waiting for IP assignment")
        guard let flower = self.flower else
        {
            self.appLog.error("🛑 Current connection is nil, giving up. 🛑")
            throw ProxyError.disconnected
        }


        self.appLog.debug("calling flowerConnection.readMessage()")
        let message = flower.readMessage()
        self.appLog.debug("finished calling flowerConnection.readMessage()")

        let proxyAddress: TunnelAddress
        switch message
        {
            case .IPAssignV4(let ipv4Address):
                proxyAddress = .ipV4(ipv4Address)

            case .IPAssignV6(let ipv6Address):
                proxyAddress = .ipV6(ipv6Address)

            case .IPAssignDualStack(let ipv4Address, let ipv6Address):
                proxyAddress = .dualStack(ipv4Address, ipv6Address)

            default:
                throw MoonbounceUniverseError.noIpAssignment
        }

        self.appLog.debug("(setProxySettings) host: \(host), proxyAddress: \(proxyAddress)")

        return // Success!
    }

    override public func stopProxy(with: NEProviderStopReason)
    {
        appLog.debug("stopProxy Called")
        self.network?.close()

        self.network = nil
        self.flower = nil
    }

    override public func handleAppMessage(data: Data) -> Data?
    {
        var responseString = "Nothing to see here!"

        if let logMessage = self.logQueue.dequeue()
        {
            responseString = "\n*******\(logMessage)*******\n"
        }

        return responseString.data
    }
}
