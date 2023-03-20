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
        self.flower = FlowerConnection(connection: transmissionConnection, log: logger)

        self.logger.debug("🌲 Connection state is ready 🌲\n")
        
        guard let flower = self.flower else
        {
            self.logger.error("🛑 Current connection is nil, giving up. 🛑")
            return TunnelError.disconnected
        }
        
        // TODO: Send IPv4 Request
        self.logger.debug("👾 PacketTunnelNetworkExtension: Sending an IP assignment request")
        flower.writeMessage(message: .IPRequestV4)
        self.logger.debug("👾 PacketTunnelNetworkExtension: Finished Sending an IP assignment request")
        sleep(5)

//        self.logger.debug("👾 PacketTunnelNetworkExtension: Trying to read an IP assignment from flowerConnection")
//        let message = flower.readMessage()
//
//        let tunnelAddress: TunnelAddress
//        switch message
//        {
//            case .IPAssignV4(let ipv4Address):
//                self.logger.debug("👾 PacketTunnelNetworkExtension: received an IPV4 assignment flower message")
//                tunnelAddress = .ipV4(ipv4Address)
//
//            case .IPAssignV6(let ipv6Address):
//                self.logger.debug("👾 PacketTunnelNetworkExtension: received an IPV6 assignment flower message")
//                tunnelAddress = .ipV6(ipv6Address)
//
//            case .IPAssignDualStack(let ipv4Address, let ipv6Address):
//                self.logger.debug("👾 PacketTunnelNetworkExtension: received a dual stack IP assignment flower message")
//                tunnelAddress = .dualStack(ipv4Address, ipv6Address)
//
//            default:
//                self.logger.debug("👾 PacketTunnelNetworkExtension: received a flower message that was not an IP assignment: \(message.debugDescription, privacy: .public)")
//                return MoonbounceUniverseError.noIpAssignment
//        }
//
//        self.logger.log("👾 MoonbounceLibrary: (setTunnelSettings) host: \(serverAddress), tunnelAddress: \(tunnelAddress.description)")
//
//        do
//        {
//            // Set the virtual interface settings.
//            try self.setNetworkTunnelSettings(serverAddress, tunnelAddress)
//        }
//        catch
//        {
//            return MoonbounceUniverseError.failure
//        }

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
