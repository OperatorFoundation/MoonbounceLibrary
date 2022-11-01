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
        self.logger.debug("PacketTunnelNetworkExtension.startTunnel")
        logger.debug("1. 👾 PacketTunnelProvider startTunnel called 👾")

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
            logger.error("Unable to get the server address.")
            return PacketTunnelProviderError.savedProtocolConfigurationIsInvalid
        }

        self.logger.debug("Server address: \(serverAddress)")

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
        
        guard let shadowConfig = configuration.providerConfiguration?[Keys.shadowConfigKey.rawValue] as? ShadowConfig else
        {
            self.logger.error("Failed to get the Shadow config from our configuration.")
            return MoonbounceUniverseError.noTransportConfig
        }
        
        // TODO: Port from config
//        let port = shadowConfig.port
        let port: UInt16 = 1234

        self.logger.debug("2. Connect to server called.\nHost - \(serverAddress)\nPort - \(port)\n")
        
        guard let transmissionConnection = try? connect(serverAddress, Int(port)) else
        {
            logger.error("could not initialize a transmission connection")
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

        self.logger.debug("(setTunnelSettings) host: \(serverAddress), tunnelAddress: \(tunnelAddress)")

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
        self.logger.debug("PacketTunnelNetworkExtension.stopTunnel")
        logger.debug("stopTunnel Called")
        self.network?.close()

        self.network = nil
        self.flower = nil
    }

    public func getConfiguration() throws -> NEVPNProtocol
    {
        self.logger.debug("PacketTunnelNetworkExtension.getConfiguration")
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
