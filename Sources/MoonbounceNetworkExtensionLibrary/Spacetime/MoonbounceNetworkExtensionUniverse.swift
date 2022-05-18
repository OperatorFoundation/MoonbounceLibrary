//
//  MoonbounceNetworkExtensionUniverse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Chord
import Flower
import Foundation
import Logging
import MoonbounceShared
import NetworkExtension
import Spacetime
import Transmission
import Universe

open class MoonbounceNetworkExtensionUniverse: Universe
{
    var logger: Logger!
    var network: Transmission.Connection? = nil
    var flower: FlowerConnection? = nil
    let messagesToPacketsQueue = DispatchQueue(label: "clientTunnelConnection: messagesToPackets")
    let packetsToMessagesQueue = DispatchQueue(label: "clientTunnelConnection: packetsToMessages")

    public init(effects: BlockingQueue<Effect>, events: BlockingQueue<Event>, logger: Logger)
    {
        self.logger = Logger(label: "MoonbounceNetworkExtension")
        self.logger.logLevel = .debug
        self.logger.debug("Initialized MoonbounceNetworkExtensionUniverse")

        self.logger.debug("MoonbounceNetworkExtensionUniverse.init")
        super.init(effects: effects, events: events)
    }

    override open func processEvent(_ event: Event)
    {
        self.logger.debug("MoonbounceNetworkExtensionUniverse.processEvent")
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
                        logger.error("startTunnel bad response: \(response)")
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
                        logger.error("stopTunnel bad response: \(response)")
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
                        logger.error("handleAppMessage bad response: \(response)")
                }

            default:
                logger.error("Unknown event \(event)")
                return
        }
    }

    /// Make the initial readPacketsWithCompletionHandler call.
    public func startHandlingPackets()
    {
        self.logger.debug("MoonbounceNetworkExtensionUniverse.startHandlingPackets")
        self.logger.debug("7. Start handling packets called.")

        packetsToMessagesQueue.async
        {
            self.logger.debug("calling packetsToMessages async")

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
            self.logger.debug("calling messagesToPackets async")

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
        throw MoonbounceUniverseError.unimplemented
    }

    public func handleAppMessage(data: Data) -> Data?
    {
        return nil
    }

    public func readPacket() throws -> Data
    {
        throw MoonbounceUniverseError.unimplemented
    }

    public func writePacket(_ data: Data) throws
    {
        throw MoonbounceUniverseError.unimplemented
    }

    public func setNetworkTunnelSettings(_ host: String, _ tunnelAddress: TunnelAddress) throws
    {
        throw MoonbounceUniverseError.unimplemented
    }

    /// Handle packets coming from the packet flow.
    func packetsToMessages() throws
    {
        throw MoonbounceUniverseError.unimplemented
    }

    func messagesToPackets() throws
    {
        throw MoonbounceUniverseError.unimplemented
    }
}

public enum MoonbounceUniverseError: Error
{
    case failure
    case connectionFailed
    case noIpAssignment
    case unimplemented
}
