//
//  VPNModule.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Chord
import Foundation
import NetworkExtension
import Simulation
import Spacetime

public class VPNModule: Module
{
    static public let name = "VPN"

    var manager: NETunnelProviderManager? = nil

    public init()
    {
    }

    public func name() -> String
    {
        return VPNModule.name
    }

    public func handleEffect(_ effect: Effect, _ channel: BlockingQueue<Event>) -> Event?
    {
        switch effect
        {
            case let loadPreferencesRequest as LoadPreferencesRequest:
                return loadPreferences(loadPreferencesRequest)

            case let savePreferencesRequest as SavePreferencesRequest:
                return savePreferences(savePreferencesRequest)

            case let enableRequest as EnableRequest:
                return enable(enableRequest)

            case let disableRequest as DisableRequest:
                return disable(disableRequest)

            case let connectionStatusRequest as ConnectionStatusRequest:
                return connectionStatus(connectionStatusRequest)

            case let sendProviderMessageRequest as SendProviderMessageRequest:
                return sendProviderMessage(sendProviderMessageRequest)

            default:
                print("Unknown effect \(effect)")
                return Failure(effect.id)
        }
    }

    public func handleExternalEvent(_ event: Event)
    {
        return
    }

    func loadPreferences(_ effect: LoadPreferencesRequest) -> Event?
    {
        if self.manager == nil
        {
            let manager = NETunnelProviderManager()

            let maybeError = Synchronizer.sync(manager.loadFromPreferences)
            if let error = maybeError
            {
                print("VPNModule.savePreferences - error: \(error)")
                return Failure(effect.id)
            }

            self.manager = manager
        }

        guard let protocolConfiguration = self.manager?.protocolConfiguration else
        {
            return Failure(effect.id)
        }

        guard let typedProtocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol else
        {
            return Failure(effect.id)
        }

        guard let description = self.manager?.localizedDescription else
        {
            return Failure(effect.id)
        }

        guard let enabled = self.manager?.isEnabled else
        {
            return Failure(effect.id)
        }

        let preferences = VPNPreferences(protocolConfiguration: typedProtocolConfiguration, description: description, enabled: enabled)

        return LoadPreferencesResponse(effect.id, preferences)
    }

    func savePreferences(_ effect: SavePreferencesRequest) -> Event?
    {
        guard let manager = self.manager else
        {
            return Failure(effect.id)
        }

        manager.protocolConfiguration = effect.preferences.protocolConfiguration
        manager.localizedDescription = effect.preferences.description
        manager.isEnabled = effect.preferences.enabled

        if let error = Synchronizer.sync(manager.saveToPreferences)
        {
            print("VPNModule.savePreferences - error: \(error)")
            return Failure(effect.id)
        }

        return SavePreferencesResponse(effect.id)
    }

    func enable(_ effect: EnableRequest) -> Event?
    {
        guard let manager = self.manager else
        {
            return Failure(effect.id)
        }

        manager.isEnabled = true

        if let error = Synchronizer.sync(manager.saveToPreferences)
        {
            print("VPNModule.enable - error: \(error)")
            return Failure(effect.id)
        }

        return EnableResponse(effect.id)
    }

    func disable(_ effect: DisableRequest) -> Event?
    {
        guard let manager = self.manager else
        {
            return Failure(effect.id)
        }

        manager.isEnabled = false

        if let error = Synchronizer.sync(manager.saveToPreferences)
        {
            print("VPNModule.disable - error: \(error)")
            return Failure(effect.id)
        }

        return DisableResponse(effect.id)
    }

    func connectionStatus(_ effect: ConnectionStatusRequest) -> Event?
    {
        guard let manager = self.manager else
        {
            return Failure(effect.id)
        }

        guard let session = manager.connection as? NETunnelProviderSession else
        {
            return Failure(effect.id)
        }

        return ConnectionStatusResponse(effect.id, session.status)
    }

    func sendProviderMessage(_ effect: SendProviderMessageRequest) -> Event?
    {
        guard let manager = self.manager else
        {
            return Failure(effect.id)
        }

        guard let session = manager.connection as? NETunnelProviderSession else
        {
            return Failure(effect.id)
        }

        let maybeResponse: Data?
        do
        {
            maybeResponse = try Synchronizer.syncThrows({completion in return try session.sendProviderMessage(effect.message, responseHandler: completion)})
        }
        catch
        {
            NSLog("Failed to send a message to the provider \(error)")
            return Failure(effect.id)
        }

        guard let response = maybeResponse else
        {
            return Failure(effect.id)
        }

        return SendProviderMessageResponse(effect.id, response)
    }
}
