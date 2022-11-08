//
//  MoonbounceLibrary.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import os.log
import NetworkExtension

import ShadowSwift
import Simulation
import Spacetime
import Universe
import MoonbounceShared

public class MoonbounceLibrary
{
    let logger: Logger
    let simulation: Simulation
    let universe: MoonbounceUniverse

    public init(logger: Logger)
    {
        let vpnModule = VPNModule()
        
        self.logger = logger
        self.simulation = Simulation(capabilities: Capabilities(BuiltinModuleNames.display.rawValue, VPNModule.name), userModules: [vpnModule], logger: logger)
        self.universe = MoonbounceUniverse(effects: self.simulation.effects, events: self.simulation.events, logger: logger)
    }

    public func configure(_ config: ShadowConfig, providerBundleIdentifier: String, tunnelName: String) throws
    {
        let _ = try? self.universe.loadPreferences()

        guard let preferences = newProtocolConfiguration(shadowConfig: config, providerBundleIdentifier: providerBundleIdentifier, tunnelName: tunnelName) else
        {
            throw MoonbounceLibraryError.badShadowConfig(config)
        }

        try self.universe.savePreferences(preferences)
    }

    public func startVPN() throws
    {
        try self.universe.enable()
    }

    public func stopVPN() throws
    {
        try self.universe.disable()
    }

    func newProtocolConfiguration(shadowConfig: ShadowConfig, providerBundleIdentifier: String, tunnelName: String) -> VPNPreferences?
    {
        self.logger.debug("VPNPreferencesController.newProtocolConfiguration")
        self.logger.debug("\n----->Setting the providerBundleIdentifier to \(providerBundleIdentifier)")

        let protocolConfiguration: NETunnelProviderProtocol = NETunnelProviderProtocol()
        protocolConfiguration.providerBundleIdentifier = providerBundleIdentifier
        protocolConfiguration.serverAddress = shadowConfig.serverIP
        protocolConfiguration.includeAllNetworks = true

        let encoder = JSONEncoder()
        guard let shadowConfigString = try? encoder.encode(shadowConfig) else
        {
            self.logger.error("Failed to create a json string from our Shadow config.")
            return nil
        }
        
        protocolConfiguration.providerConfiguration = [
            Keys.shadowConfigKey.rawValue: shadowConfigString.data,
            Keys.tunnelNameKey.rawValue: tunnelName
        ]

        self.logger.info("newProtocolConfiguration: \(String(describing: protocolConfiguration.providerConfiguration))")

        let preferences = VPNPreferences(protocolConfiguration: protocolConfiguration, description: "Moonbounce", enabled: true)

        return preferences
    }
}

public enum MoonbounceLibraryError: Error
{
    case badConfig(MoonbounceConfig)
    case badShadowConfig(ShadowConfig)
}
