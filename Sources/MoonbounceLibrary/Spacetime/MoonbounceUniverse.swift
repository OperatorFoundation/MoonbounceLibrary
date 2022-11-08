//
//  MoonbounceUniverse.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Chord
import Foundation
import os.log
import MoonbounceShared
import NetworkExtension
import Spacetime
import Universe

public class MoonbounceUniverse: Universe
{
    let logger: Logger

    public init(effects: BlockingQueue<Effect>, events: BlockingQueue<Event>, logger: Logger)
    {
        self.logger = logger

        super.init(effects: effects, events: events, logger: logger)
    }

    public func connectionStatus() throws -> NEVPNStatus
    {
        let response = processEffect(ConnectionStatusRequest())
        switch response
        {
            case let connectionStatusResponse as ConnectionStatusResponse:
                return connectionStatusResponse.status

            default:
                throw MoonbounceUniverseError.failure
        }
    }

    public func disable() throws
    {
        let response = processEffect(DisableRequest())
        switch response
        {
            case is DisableResponse:
                return

            default:
                throw MoonbounceUniverseError.failure
        }
    }

    public func enable() throws
    {
        let response = processEffect(EnableRequest())
        switch response
        {
            case is EnableResponse:
                return

            default:
                throw MoonbounceUniverseError.failure
        }
    }

    public func loadPreferences() throws -> VPNPreferences
    {
        let request = LoadPreferencesRequest()
        let response = processEffect(request)
        
        switch response
        {
            case let loadPreferencesResponse as LoadPreferencesResponse:
                return loadPreferencesResponse.preferences

            default:
                throw MoonbounceUniverseError.failure
        }
    }

    public func savePreferences(_ preferences: VPNPreferences) throws
    {
        let response = processEffect(SavePreferencesRequest(preferences))
        switch response
        {
            case is SavePreferencesResponse:
                return

            default:
                throw MoonbounceUniverseError.failure
        }
    }

    public func sendProviderMessage(_ data: Data) throws -> Data
    {
        let response = processEffect(SendProviderMessageRequest(data))
        switch response
        {
            case let sendProvidesMessageResponse as SendProviderMessageResponse:
                return sendProvidesMessageResponse.message

            default:
                throw MoonbounceUniverseError.failure
        }
    }
}

public enum MoonbounceUniverseError: Error
{
    case failure
}
