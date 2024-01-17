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
import InternetProtocols

open class MoonbouncePacketTunnelProvider: NEPacketTunnelProvider
{
    static let lengthPrefixSize = 32
    
    let neModule: NetworkExtensionModule
    var logger = Logger(subsystem: "org.OperatorFoundation.MoonbounceLogger", category: "NetworkExtension")

    /// The tunnel connection.
    var network: Transmission.Connection?
    
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
    public override func startTunnel(options: [String : NSObject]? = nil) async throws
    {
        self.logger.log("MoonbouncePacketTunnelProvider: startTunnel")
        
        let serverAddress: String
        
        logger.log("👾 PacketTunnelNetworkExtension: getting configuration... 👾")
        serverAddress = try neModule.getTunnelConfiguration()
        logger.log("👾 PacketTunnelNetworkExtension: received a configuration: \(serverAddress.description) 👾")
        logger.log("👾 PacketTunnelNetworkExtension: Server address: \(serverAddress.description)")

        let serverAddressList = serverAddress.replacingOccurrences(of: " ", with: "").components(separatedBy: ":")
        let host = serverAddressList[0]
        let portString = serverAddressList[1]
        guard let port = UInt16(portString) else
        {
            self.logger.log("Error: Failed to start a tunnel, the server port is invalid: \(portString)")
            throw PacketTunnelProviderError.couldNotSetNetworkSettings
        }

        logger.log("👾 PacketTunnelNetworkExtension: Connect to server called.\nHost - \(host)\nPort - \(port)👾")

        guard let transmissionConnection = TCPConnection(host: host, port: Int(port), logger: logger) else 
        {
            self.logger.log("Error: Failed to make a TCP connection")
            throw PacketTunnelProviderError.tcpConnectionFailed
        }

        logger.log("PacketTunnelNetworkExtension.startTunnel() got TransmissionConnection")

        self.network = transmissionConnection

        self.logger.log("🌲 Connection state is ready 🌲\n")

        // Set the virtual interface settings.
        do
        {
            try await neModule.setNetworkTunnelSettings(host: host, tunnelAddress: TunnelAddress.ipV4(IPv4Address("10.0.0.1")!))
            self.neModule.setConfiguration(self.protocolConfiguration)
            
            Task {
                await vpnToServer()
            }
            
            Task {
                serverToVPN()
            }
        }
        catch (let error)
        {
            self.logger.error("‼️Received an error while setting NetworkTunnelSettings: \(error)‼️")
        }
        
    }


    public override func stopTunnel(with reason: NEProviderStopReason) async
    {
        self.logger.log("MoonbouncePacketTunnelProvider: stopTunnel")
        self.network?.close()
        self.network = nil
    }
    
    /// Handle IPC messages from the app.
    public override func handleAppMessage(_ messageData: Data) async -> Data?
    {
        self.logger.debug("MoonbouncePacketTunnelProvider: handleAppMessage")
        // TODO: add data processing at a later time
        return nil
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
    
    
    // FIXME: Experimental version of this function.
    // Original is commented out below
    private func vpnToServer() async
    {
        logger.log("★ vpnToServer called.")
        while true
        {
            guard let connection = self.network else
            {
                logger.log("★ vpnToServer connection failed")
                return
            }
            
            let packets: [NEPacket] = await packetFlow.readPacketObjects()
            
            for packet in packets
            {
                logger.log("★ vpnToServer read \(packet.data.count) bytes.")
                guard connection.writeWithLengthPrefix(data: packet.data, prefixSizeInBits: Self.lengthPrefixSize) else
                {
                    logger.log("★ vpnToServer write failed")
                    return
                }
                
                self.logger.log("★ vpnToServer: packet metadata: \(packet.metadata)")
                self.logger.log("★ vpnToServer: packet data (\(packet.data.count) bytes): \(packet.data.hex)")
                let ipv4packet = Packet(ipv4Bytes: packet.data, timestamp: Date(), debugPrints: true)
                if let ipv4packetproperty = ipv4packet.ipv4
                {
                    let destination = ipv4packetproperty.destinationAddress.hex
                    self.logger.log("★ vpnToServer: writePacket DEBUG created an IPv4Packet with destination: \(destination)")
                }
                
                logger.log("★ vpnToServer wrote \(packet.data.count) bytes.")
            }
        }
    }
    
//    private func vpnToServer() async 
//    {
//        logger.log("★ vpnToServer called.")
//        while true
//        {
//            guard let connection = self.network else
//            {
//                logger.log("★ vpnToServer connection failed")
//                return
//            }
//
//            let (bytesRead, protocols) = await packetFlow.readPackets()
//            
//            for (index, packet) in bytesRead.enumerated()
//            {
//                guard protocols[index] == NSNumber(value: AF_INET) else
//                {
//                    logger.log("★ vpnToServer read a packet with an unsupported protocol. Skipping.")
//                    continue
//                }
//                logger.log("★ vpnToServer read \(packet.count) bytes.")
//                
//                guard connection.writeWithLengthPrefix(data: packet, prefixSizeInBits: Self.lengthPrefixSize) else
//                {
//                    logger.log("★ vpnToServer write failed")
//                    return
//                }
//                
//                logger.log("★ vpnToServer wrote \(packet.count) bytes.")
//            }
//            
//        }
//    }
    
    private func serverToVPN() 
    {
        logger.log("✩ serverToVPN called")
        
        while true
        {
            guard let connection = self.network else
            {
                logger.log("✩ serverToVPN connection failed")
                return
            }
                        
            guard let bytesRead = connection.readWithLengthPrefix(prefixSizeInBits: Self.lengthPrefixSize) else {
                logger.log("✩ serverToVPN read failed")
                return
            }
            logger.log("✩ serverToVPN read \(bytesRead.count) bytes: \(bytesRead.hex)")
            
            packetFlow.writePackets([bytesRead], withProtocols: [NSNumber(value: AF_INET)])
            logger.log("✩ serverToVPN wrote the bytes read (\(bytesRead.count) bytes)")
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
    case tcpConnectionFailed
}
