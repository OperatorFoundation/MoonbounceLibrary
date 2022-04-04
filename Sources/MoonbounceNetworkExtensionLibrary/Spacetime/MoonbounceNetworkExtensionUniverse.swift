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

        let remoteHost = serverAddress
        self.appLog.debug("Server address: \(serverAddress)")

        guard let moonbounceConfig = NetworkExtensionConfigController.getMoonbounceConfig(fromProtocolConfiguration: configuration) else
        {
            appLog.error("Unable to get moonbounce config from protocol.")
            return PacketTunnelProviderError.savedProtocolConfigurationIsInvalid
        }

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
        guard let replicantConnection = TransmissionConnection(host: "127.0.0.1", port: 1234) else
        {
            appLog.error("could not initialize replicant connection")
            return MoonbounceUniverseError.connectionFailed
        }
        self.network = replicantConnection

        self.flower = FlowerConnection(connection: replicantConnection)

        self.appLog.debug("\n3. 🌲 Connection state is ready 🌲\n")

        return nil
        //return self.waitForIPAssignment()
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
}

public enum MoonbounceUniverseError: Error
{
    case failure
    case connectionFailed
}
