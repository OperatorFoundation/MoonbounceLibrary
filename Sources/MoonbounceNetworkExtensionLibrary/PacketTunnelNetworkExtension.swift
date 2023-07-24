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

import MoonbounceShared
import ShadowSwift
import Simulation
import Spacetime
import Transmission
import Universe

// this is where the actual application logic is
open class PacketTunnelNetworkExtension: MoonbounceNetworkExtensionUniverse
{
    override public func startTunnel(options: [String: NSObject]?) async -> Error?
    {
        logger.log("👾 PacketTunnelNetworkExtension: startTunnel called 👾")

        let serverAddress: String
        do
        {
            logger.log("👾 PacketTunnelNetworkExtension: getting configuration... 👾")
            serverAddress = try self.getTunnelConfiguration()
            logger.log("👾 PacketTunnelNetworkExtension: received a configuration: \(serverAddress.description) 👾")
        }
        catch
        {
            logger.log("👾 PacketTunnelNetworkExtension: Failed to get the configuration 👾")
            return error
        }

        logger.log("👾 PacketTunnelNetworkExtension: Server address: \(serverAddress.description)")
        
        let serverAddressList = serverAddress.components(separatedBy: ":")
        let host = serverAddressList[0]
        let portString = serverAddressList[1]
        let port = UInt16(string: portString)

        logger.log("👾 PacketTunnelNetworkExtension: Connect to server called.\nHost - \(host)\nPort - \(port)👾")
        
        guard let transmissionConnection = try? connect(host, Int(port)) else
        {
            logger.error("PacketTunnelNetworkExtension: could not initialize a transmission connection")
            return MoonbounceUniverseError.connectionFailed
        }
        
        logger.log("PacketTunnelNetworkExtension.startTunnel() got TransmissionConnection")

        self.network = transmissionConnection

        self.logger.log("🌲 Connection state is ready 🌲\n")

        do
        {
            // Set the virtual interface settings.
            try self.setNetworkTunnelSettings(serverAddress, TunnelAddress.ipV4(IPv4Address("10.0.0.1")!))
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
