//
//  MoonbounceNetworkExtensionUniverse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Chord
import Flower
import Foundation
import os.log
import MoonbounceShared
import NetworkExtension
import Spacetime
import Transmission
import Universe

open class MoonbounceNetworkExtensionUniverse: Universe
{
    var logger: Logger
    var network: Transmission.Connection? = nil
    var flower: FlowerConnection? = nil
    let messagesToPacketsQueue = DispatchQueue(label: "clientTunnelConnection: messagesToPackets")
    let packetsToMessagesQueue = DispatchQueue(label: "clientTunnelConnection: packetsToMessages")

    public init(effects: BlockingQueue<Effect>, events: BlockingQueue<Event>, logger: Logger)
    {
        self.logger = logger
        self.logger.log("MoonbounceNetworkExtensionUniverse: Initialized MoonbounceNetworkExtensionUniverse")
        super.init(effects: effects, events: events)
    }

    override open func processEvent(_ event: Event)
    {
        self.logger.log("MoonbounceNetworkExtensionUniverse: processEvent")
        switch event
        {
            case let startTunnelEvent as StartTunnelEvent:
                logger.log("MoonbounceNetworkExtensionUniverse: StartTunnelEvent")
                let result = self.startTunnel(options: startTunnelEvent.options)
                let request = StartTunnelRequest(result)
                let response = self.processEffect(request)
                switch response
                {
                    case is StartTunnelResponse:
                        return

                    default:
                        logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: startTunnel bad response: \(response)")
                }

            case let stopTunnelEvent as StopTunnelEvent:
                logger.log("MoonbounceNetworkExtensionUniverse: StopTunnelEvent")
                self.stopTunnel(with: stopTunnelEvent.reason)
                let request = StopTunnelRequest()
                let response = self.processEffect(request)
                switch response
                {
                    case is StopTunnelResponse:
                        return

                    default:
                        logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: stopTunnel bad response: \(response)")
                }

            case let appMessageEvent as AppMessageEvent:
                logger.log("MoonbounceNetworkExtensionUniverse: AppMessageEvent")
                let result = self.handleAppMessage(data: appMessageEvent.data)
                let request = AppMessageRequest(result)
                let response = self.processEffect(request)
                switch response
                {
                    case is AppMessageResponse:
                        return

                    default:
                        logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: handleAppMessage bad response: \(response)")
                }

            default:
                logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: Unknown event \(event)")
                return
        }
    }

    /// Make the initial readPacketsWithCompletionHandler call.
    public func startHandlingPackets()
    {
        self.logger.log("MoonbounceNetworkExtensionUniverse: startHandlingPackets")

        packetsToMessagesQueue.async
        {
            self.logger.debug("MoonbounceNetworkExtensionUniverse: calling packetsToMessages async")

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
            self.logger.log("MoonbounceNetworkExtensionUniverse: calling messagesToPackets async")

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

    // To be implemented by subclasses
    public func startTunnel(options: [String: NSObject]?) -> Error?
    {
        return nil // Success!
    }

    public func stopTunnel(with: NEProviderStopReason)
    {
        return
    }

    public func getConfiguration() throws -> NETunnelProviderProtocol
    {
        self.logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: calling getConfiguration but it is not implemented.")
        throw MoonbounceUniverseError.unimplemented
    }

    public func handleAppMessage(data: Data) -> Data?
    {
        self.logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: calling handleAppMessage but it is not implemented.")
        return nil
    }

    public func readPacket() throws -> Data
    {
        self.logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: calling readPacket but it is not implemented.")
        throw MoonbounceUniverseError.unimplemented
    }

    public func writePacket(_ data: Data) throws
    {
        self.logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: calling writePacket but it is not implemented.")
        throw MoonbounceUniverseError.unimplemented
    }

    public func setNetworkTunnelSettings(_ host: String, _ tunnelAddress: TunnelAddress) throws
    {
        self.logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: calling setNetworkTunnelSettings but it is not implemented.")
        throw MoonbounceUniverseError.unimplemented
    }

    /// Handle packets coming from the packet flow.
    func packetsToMessages() throws
    {
        self.logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: calling packetsToMessages but it is not implemented.")
        throw MoonbounceUniverseError.unimplemented
    }

    func messagesToPackets() throws
    {
        self.logger.log(level: .error, "MoonbounceNetworkExtensionUniverse: calling messagesToPackets but it is not implemented.")
        throw MoonbounceUniverseError.unimplemented
    }
}

public enum MoonbounceUniverseError: Error
{
    case failure
    case connectionFailed
    case noTransportConfig
    case noIpAssignment
    case unimplemented
}
