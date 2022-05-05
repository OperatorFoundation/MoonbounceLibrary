//
//  PacketTunnelNetworkExtension.swift
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

open class PacketTunnelNetworkExtension: MoonbounceNetworkExtensionUniverse
{
    override public func startTunnel(options: [String: NSObject]?) -> Error?
    {
        appLog.debug("1. 👾 PacketTunnelProvider startTunnel called 👾")

        let configuration: NETunnelProviderProtocol
        do
        {
            configuration = try getConfiguration()
        }
        catch
        {
            return error
        }

        guard let serverAddress: String = configuration.serverAddress else
        {
            appLog.error("Unable to get the server address.")
            return PacketTunnelProviderError.savedProtocolConfigurationIsInvalid
        }

        self.appLog.debug("Server address: \(serverAddress)")

        //        guard let moonbounceConfig = NetworkExtensionConfigController.getMoonbounceConfig(fromProtocolConfiguration: configuration) else
        //        {
        //            appLog.error("Unable to get moonbounce config from protocol.")
        //            return PacketTunnelProviderError.savedProtocolConfigurationIsInvalid
        //        }

        //        guard let replicantConfig = moonbounceConfig.replicantConfig
        //            else
        //        {
        //            self.log.debug("start tunnel failed to find a replicant configuration")
        //            completionHandler(TunnelError.badConfiguration)
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
            return MoonbounceUniverseError.connectionFailed
        }
        self.network = replicantConnection

        self.flower = FlowerConnection(connection: replicantConnection)

        self.appLog.debug("\n3. 🌲 Connection state is ready 🌲\n")
        self.appLog.debug("Waiting for IP assignment")
        guard let flower = self.flower else
        {
            self.appLog.error("🛑 Current connection is nil, giving up. 🛑")
            return TunnelError.disconnected
        }


        self.appLog.debug("calling flowerConnection.readMessage()")
        let message = flower.readMessage()
        self.appLog.debug("finished calling flowerConnection.readMessage()")

        let tunnelAddress: TunnelAddress
        switch message
        {
            case .IPAssignV4(let ipv4Address):
                tunnelAddress = .ipV4(ipv4Address)

            case .IPAssignV6(let ipv6Address):
                tunnelAddress = .ipV6(ipv6Address)

            case .IPAssignDualStack(let ipv4Address, let ipv6Address):
                tunnelAddress = .dualStack(ipv4Address, ipv6Address)

            default:
                return MoonbounceUniverseError.noIpAssignment
        }

        self.appLog.debug("(setTunnelSettings) host: \(host), tunnelAddress: \(tunnelAddress)")

        do
        {
            // Set the virtual interface settings.
            try self.setNetworkTunnelSettings(host, tunnelAddress)
        }
        catch
        {
            return MoonbounceUniverseError.failure
        }

        return nil // Success!
    }

    override public func stopTunnel(with: NEProviderStopReason)
    {
        appLog.debug("stopTunnel Called")
        self.network?.close()

        self.network = nil
        self.flower = nil
    }

    override public func getConfiguration() throws -> NETunnelProviderProtocol
    {
        let response = processEffect(GetConfigurationRequest())
        switch response
        {
            case let getConfigurationResponse as GetConfigurationResponse:
                return getConfigurationResponse.configuration

            default:
                throw MoonbounceUniverseError.failure
        }
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

    override public func readPacket() throws -> Data
    {
        let response = processEffect(ReadPacketRequest())
        switch response
        {
            case let readPacketResponse as ReadPacketResponse:
                return readPacketResponse.data

            default:
                throw MoonbounceUniverseError.failure
        }
    }

    override public func writePacket(_ data: Data) throws
    {
        let response = processEffect(WritePacketRequest(data))
        switch response
        {
            case is WritePacketResponse:
                return

            default:
                throw MoonbounceUniverseError.failure
        }
    }

    override public func setNetworkTunnelSettings(_ host: String, _ tunnelAddress: TunnelAddress) throws
    {
        let response = processEffect(SetNetworkTunnelSettingsRequest(host, tunnelAddress))
        switch response
        {
            case is SetNetworkTunnelSettingsResponse:
                return

            default:
                throw MoonbounceUniverseError.failure
        }
    }
}
