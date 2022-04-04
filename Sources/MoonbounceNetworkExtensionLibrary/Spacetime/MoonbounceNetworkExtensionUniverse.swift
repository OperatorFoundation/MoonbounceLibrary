//
//  MoonbounceNetworkExtensionUniverse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Chord
import Flower
import Foundation
import LoggerQueue
import Logging
import MoonbounceShared
import NetworkExtension
import Spacetime
import Transmission
import Universe

public class MoonbounceNetworkExtensionUniverse: Universe
{
    let appLog: Logger
    let logQueue: LoggerQueue
    var network: Transmission.Connection? = nil
    var flower: FlowerConnection? = nil
    let messagesToPacketsQueue = DispatchQueue(label: "clientTunnelConnection: messagesToPackets")
    let packetsToMessagesQueue = DispatchQueue(label: "clientTunnelConnection: packetsToMessages")

    public init(effects: BlockingQueue<Effect>, events: BlockingQueue<Event>, logger: Logger, logQueue: LoggerQueue)
    {
        self.appLog = logger
        self.logQueue = logQueue

        super.init(effects: effects, events: events)
    }

    override open func processEvent(_ event: Event)
    {
        switch event
        {
            case let startTunnelEvent as StartTunnelEvent:
                let result = self.startTunnel(options: startTunnelEvent.options)
                let request = StartTunnelRequest(result)
                let response = self.processEffect(request)
                switch response
                {
                    case is StartTunnelResponse:
                        return

                    default:
                        appLog.error("startTunnel bad response: \(response)")
                }

            case let stopTunnelEvent as StopTunnelEvent:
                self.stopTunnel(with: stopTunnelEvent.reason)
                let request = StopTunnelRequest()
                let response = self.processEffect(request)
                switch response
                {
                    case is StopTunnelResponse:
                        return

                    default:
                        appLog.error("stopTunnel bad response: \(response)")
                }

            case let appMessageEvent as AppMessageEvent:
                let result = self.handleAppMessage(data: appMessageEvent.data)
                let request = AppMessageRequest(result)
                let response = self.processEffect(request)
                switch response
                {
                    case is AppMessageResponse:
                        return

                    default:
                        appLog.error("handleAppMessage bad response: \(response)")
                }

            default:
                appLog.error("Unknown event \(event)")
                return
        }
    }

    public func startTunnel(options: [String: NSObject]?) -> Error?
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

        let host = "127.0.0.1"
        let port = 1234

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

    public func stopTunnel(with: NEProviderStopReason)
    {
        appLog.debug("stopTunnel Called")
        self.network?.close()

        self.network = nil
        self.flower = nil
    }

    public func getConfiguration() throws -> NETunnelProviderProtocol
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

    public func handleAppMessage(data: Data) -> Data?
    {
        var responseString = "Nothing to see here!"

        if let logMessage = self.logQueue.dequeue()
        {
            responseString = "\n*******\(logMessage)*******\n"
        }

        return responseString.data
    }

    public func readPacket() throws -> Data
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

    public func writePacket(_ data: Data) throws
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

    public func setNetworkTunnelSettings(_ host: String, _ tunnelAddress: TunnelAddress) throws
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

    /// Make the initial readPacketsWithCompletionHandler call.
    public func startHandlingPackets()
    {
        self.appLog.debug("7. Start handling packets called.")

        packetsToMessagesQueue.async
        {
            self.appLog.debug("calling packetsToMessages async")

            do
            {
                try self.packetsToMessages()
            }
            catch
            {
                return
            }
        }

        messagesToPacketsQueue.async
        {
            self.appLog.debug("calling messagesToPackets async")

            do
            {
                try self.messagesToPackets()
            }
            catch
            {
                return
            }
        }
    }

    /// Handle packets coming from the packet flow.
    func packetsToMessages() throws
    {
        self.appLog.debug("8. Handle Packets Called")

        guard let flower = self.flower else
        {
            return
        }

        while true
        {
            let data = try self.readPacket()

            // Encapsulates packages into Messages (using Flower)
            self.appLog.debug("packet: \(data)")
            let message = Message.IPDataV4(data)
            self.appLog.debug("🌷 encapsulated into Flower Message: \(message.description) 🌷")

            flower.writeMessage(message: message)
        }
    }

    func messagesToPackets() throws
    {
        guard let flower = self.flower else
        {
            return
        }

        while true
        {
            guard let message = flower.readMessage() else {return}

            self.appLog.debug("🌷 replicantConnection.readMessages callback message: \(message.description) 🌷")
            switch message
            {
                case .IPDataV4(let data):
                    self.appLog.debug("IPDataV4 calling write packets.")
                    try self.writePacket(data)

//                case .IPDataV6(let data): // FIXME - support IPv6

                default:
                    self.appLog.error("unsupported message type")
            }
        }
    }
}

public enum MoonbounceUniverseError: Error
{
    case failure
    case connectionFailed
    case noIpAssignment
}
