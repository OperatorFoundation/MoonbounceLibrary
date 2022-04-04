//
//  LoggingController.swift
//  Moonbounce
//
//  Created by Mafalda on 5/15/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Datable
import Foundation
import Logging
import MoonbounceShared
import NetworkExtension

public class LoggingController
{
    var loggingEnabled = true
    let universe: MoonbounceUniverse
    let queue: DispatchQueue = DispatchQueue(label: "LoggingController")
    let logger: Logger

    public init(universe: MoonbounceUniverse, logger: Logger)
    {
        self.universe = universe
        self.logger = logger
    }

    // This allows us to see print statements for debugging
    public func startLoggingLoop()
    {
        loggingEnabled = true

        let status: NEVPNStatus
        do
        {
            status = try self.universe.connectionStatus()
        }
        catch
        {
            self.logger.error("LoggingController.startLoggingLoop - error: \(error)")
            return
        }

        guard status != .invalid else
        {
            self.logger.error("LoggingController.startLoggingLoop - Invalid connection status")
            return
        }

        self.queue.async
        {
            var currentStatus: NEVPNStatus = .invalid
            while self.loggingEnabled
            {
                sleep(1)

                let newStatus: NEVPNStatus
                do
                {
                    newStatus = try self.universe.connectionStatus()
                }
                catch
                {
                    self.logger.error("LoggingController.startLoggingLoop - error: \(error)")
                    return
                }

                if newStatus != currentStatus
                {
                    currentStatus = newStatus
                    self.logger.debug("\nCurrent Status Changed: \(currentStatus)\n")
                }
                
                let message = "Hello Provider".data

                do
                {
                    let response = try self.universe.sendProviderMessage(message).string
                    self.logger.debug("\(response)")
                }
                catch
                {
                    self.logger.error("LoggingController.startLoggingLoop - Failed to send a message to the provider: \(error)")
                }
            }
        }
    }

    public func stopLoggingLoop()
    {
        loggingEnabled = false
    }
}
