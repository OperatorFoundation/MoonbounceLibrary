//
//  PacketTunnelNetworkExtension.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/5/22.
//

import Foundation
import Logging
import NetworkExtension
import os.log

import Flower
import MoonbounceShared
import ShadowSwift
import Simulation
import Spacetime
import Transmission
import Universe

// this is where the actual application logic is
open class PacketTunnelNetworkExtension: MoonbounceNetworkExtensionUniverse
{
    override public func startTunnel(options: [String: NSObject]?) -> Error?
    {
        logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension startTunnel called 👾")

        let serverAddress: String
        do
        {
            logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension getting configuration... 👾")
            serverAddress = try self.getTunnelConfiguration()
            logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension received a configuration: \(serverAddress.description) 👾")
        }
        catch
        {
            logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension Failed to get the configuration 👾")
            return error
        }

        self.logger.debug("👾 MoonbounceLibrary: Server address: \(serverAddress.description)")
        logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension: Server address: \(serverAddress.description)")

//        guard let moonbounceConfig = NetworkExtensionConfigController.getMoonbounceConfig(fromProtocolConfiguration: configuration) else
//        {
//            appLog.error("Unable to get moonbounce config from protocol.")
//            return PacketTunnelProviderError.savedProtocolConfigurationIsInvalid
//        }
//
//        guard let replicantConfig = moonbounceConfig.replicantConfig
//            else
//        {
//            self.log.debug("start tunnel failed to find a replicant configuration")
//            completionHandler(TunnelError.badConfiguration)
//            return
//        }
        
//        guard let shadowConfig = tunnelProviderConfiguration.providerConfiguration?[Keys.shadowConfigKey.rawValue] as? ShadowConfig else
//        {
//            os_log("MoonbounceLibrary: Failed to get the Shadow config from our configuration.")
//            return MoonbounceUniverseError.noTransportConfig
//        }
        
        // TODO: Port from config
//        let port = shadowConfig.port
        let port: UInt16 = 1234

        logger.log("👾\nMoonbounceLibrary: Connect to server called.\nHost - \(serverAddress)\nPort - \(port)\n👾")
        
        guard let transmissionConnection = try? connect(serverAddress, Int(port)) else
        {
            logger.error("PacketTunnelNetworkExtension: could not initialize a transmission connection")
            return MoonbounceUniverseError.connectionFailed
        }

        self.network = transmissionConnection
        self.flower = FlowerConnection(connection: transmissionConnection)

        self.logger.debug("\n3. 🌲 Connection state is ready 🌲\n")
        self.logger.debug("Waiting for IP assignment")
        
        guard let flower = self.flower else
        {
            self.logger.error("🛑 Current connection is nil, giving up. 🛑")
            return TunnelError.disconnected
        }

        self.logger.debug("calling flowerConnection.readMessage()")
        let message = flower.readMessage()
        self.logger.debug("finished calling flowerConnection.readMessage()")

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

        self.logger.log("👾 MoonbounceLibrary: (setTunnelSettings) host: \(serverAddress), tunnelAddress: \(tunnelAddress.description)")

        do
        {
            // Set the virtual interface settings.
            try self.setNetworkTunnelSettings(serverAddress, tunnelAddress)
        }
        catch
        {
            return MoonbounceUniverseError.failure
        }

        return nil // Success!
    }

    override public func stopTunnel(with: NEProviderStopReason)
    {
        self.logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension stopTunnel")
        self.network?.close()

        self.network = nil
        self.flower = nil
    }

    public func getTunnelConfiguration() throws -> String
    {
        logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension: calling GetConfigurationRequest()")
        let request = GetConfigurationRequest()
        logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension: ConfigurationRequest: \(request.description)\n👾 calling processEffect()")
        let response = processEffect(request)
        logger.log("👾 MoonbounceLibrary: processEffect response: \(response)")
        
        switch response
        {
            case let getConfigurationResponse as GetConfigurationResponse:
                logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension: returning a configuration... 👾")
                return getConfigurationResponse.configuration

            default:
                logger.log("👾 MoonbounceLibrary: PacketTunnelNetworkExtension: getConfiguration failed! Received an incorrect response: \(response.description) 👾")
                throw MoonbounceUniverseError.failure
        }
    }

    override public func handleAppMessage(data: Data) -> Data?
    {
        self.logger.debug("PacketTunnelNetworkExtension.handleAppMessage")
        return nil
    }

    override public func readPacket() throws -> Data
    {
        self.logger.debug("PacketTunnelNetworkExtension.readPacket")
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
        self.logger.debug("PacketTunnelNetworkExtension.writePacket")
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
        self.logger.debug("PacketTunnelNetworkExtension.setNetworkTunnelSettings")
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
