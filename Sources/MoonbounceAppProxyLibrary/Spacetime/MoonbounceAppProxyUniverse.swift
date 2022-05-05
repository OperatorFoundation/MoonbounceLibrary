//
//  MoonbounceAppProxyUniverse.swift
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

public class MoonbounceAppProxyUniverse: Universe
{
    let appLog: Logger
    let logQueue: LoggerQueue
    var network: Transmission.Connection? = nil
    var flower: FlowerConnection? = nil
    let messagesToPacketsQueue = DispatchQueue(label: "clientProxyConnection: messagesToPackets")
    let packetsToMessagesQueue = DispatchQueue(label: "clientProxyConnection: packetsToMessages")

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
            case let startProxyEvent as StartProxyEvent:
                do
                {
                    try self.startProxy(options: startProxyEvent.options)

                    // FIXME
                    let request = StartProxyRequest(nil)
                    let response = self.processEffect(request)
                    switch response
                    {
                        case is StartProxyResponse:
                            return

                        default:
                            appLog.error("startProxy bad response: \(response)")
                            return
                    }
                }
                catch
                {
                    appLog.error("startProxy threw: \(error)")
                    return
                }

            case let stopProxyEvent as StopProxyEvent:
                self.stopProxy(with: stopProxyEvent.reason)
                let request = StopProxyRequest()
                let response = self.processEffect(request)
                switch response
                {
                    case is StopProxyResponse:
                        return

                    default:
                        appLog.error("stopProxy bad response: \(response)")
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

    public func startProxy(options: [String: Any]?) throws
    {
        appLog.debug("1. 👾 PacketProxyProvider startProxy called 👾")

        //        guard let moonbounceConfig = NetworkExtensionConfigController.getMoonbounceConfig(fromProtocolConfiguration: configuration) else
        //        {
        //            appLog.error("Unable to get moonbounce config from protocol.")
        //            return PacketProxyProviderError.savedProtocolConfigurationIsInvalid
        //        }

        //        guard let replicantConfig = moonbounceConfig.replicantConfig
        //            else
        //        {
        //            self.log.debug("start proxy failed to find a replicant configuration")
        //            completionHandler(ProxyError.badConfiguration)
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
            throw MoonbounceUniverseError.connectionFailed
        }
        self.network = replicantConnection
        self.flower = FlowerConnection(connection: replicantConnection)

        self.appLog.debug("\n3. 🌲 Connection state is ready 🌲\n")
        self.appLog.debug("Waiting for IP assignment")
        guard let flower = self.flower else
        {
            self.appLog.error("🛑 Current connection is nil, giving up. 🛑")
            throw ProxyError.disconnected
        }


        self.appLog.debug("calling flowerConnection.readMessage()")
        let message = flower.readMessage()
        self.appLog.debug("finished calling flowerConnection.readMessage()")

        let proxyAddress: TunnelAddress
        switch message
        {
            case .IPAssignV4(let ipv4Address):
                proxyAddress = .ipV4(ipv4Address)

            case .IPAssignV6(let ipv6Address):
                proxyAddress = .ipV6(ipv6Address)

            case .IPAssignDualStack(let ipv4Address, let ipv6Address):
                proxyAddress = .dualStack(ipv4Address, ipv6Address)

            default:
                throw MoonbounceUniverseError.noIpAssignment
        }

        self.appLog.debug("(setProxySettings) host: \(host), proxyAddress: \(proxyAddress)")

        return // Success!
    }

    public func stopProxy(with: NEProviderStopReason)
    {
        appLog.debug("stopProxy Called")
        self.network?.close()

        self.network = nil
        self.flower = nil
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

    public func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool
    {
        // FIXME
        return false
    }

    public func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteEndpoint remoteEndpoint: NWEndpoint) -> Bool
    {
        // FIXME
        return false
    }
}

public enum MoonbounceUniverseError: Error
{
    case failure
    case connectionFailed
    case noIpAssignment
}
