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
import MoonbounceShared

public class MoonbounceLibrary
{
    let logger: Logger
    let vpn: VPNModule

    public init(logger: Logger)
    {        
        self.logger = logger
        self.vpn = VPNModule(logger: logger)
    }

    public func configure(_ config: ShadowConfig.ShadowClientConfig, providerBundleIdentifier: String, tunnelName: String) throws
    {
        let _ = try? self.vpn.loadPreferences()
        print("✶ MoonbounceLibrary loadPreferences() returned")

        guard let preferences = newProtocolConfiguration(shadowConfig: config, providerBundleIdentifier: providerBundleIdentifier, tunnelName: tunnelName) else
        {
            throw MoonbounceLibraryError.badShadowConfig(config)
        }

        try self.vpn.savePreferences(preferences)
        print("✶ MoonbounceLibrary.configure() returned from savePreferences()")
    }

    public func startVPN() throws
    {
        print("✶ startVPN called")
        try self.vpn.enable()
    }

    public func stopVPN() throws
    {
        print("✶ stopVPN called")
        try self.vpn.disable()
    }

    func newProtocolConfiguration(shadowConfig: ShadowConfig.ShadowClientConfig, providerBundleIdentifier: String, tunnelName: String) -> VPNPreferences?
    {
        self.logger.debug("✶ VPNPreferencesController.newProtocolConfiguration")
        self.logger.debug("\n✶ ----->Setting the providerBundleIdentifier to \(providerBundleIdentifier)")

        let protocolConfiguration: NETunnelProviderProtocol = NETunnelProviderProtocol()
        protocolConfiguration.providerBundleIdentifier = providerBundleIdentifier
        protocolConfiguration.serverAddress = shadowConfig.serverAddress
        protocolConfiguration.includeAllNetworks = true

        let encoder = JSONEncoder()
        guard let shadowConfigString = try? encoder.encode(shadowConfig) else
        {
            self.logger.error("✶ Failed to create a json string from our Shadow config.")
            return nil
        }
        
        protocolConfiguration.providerConfiguration = [
            Keys.serverAddress.rawValue: shadowConfig.serverAddress,
            Keys.shadowConfigKey.rawValue: shadowConfigString.data,
            Keys.tunnelNameKey.rawValue: tunnelName
        ]

        self.logger.info("✶ newProtocolConfiguration: \(String(describing: protocolConfiguration.providerConfiguration))")

        let preferences = VPNPreferences(protocolConfiguration: protocolConfiguration, description: "Moonbounce", enabled: true)

        return preferences
    }
}

public enum MoonbounceLibraryError: Error
{
    case badConfig(MoonbounceConfig)
    case badShadowConfig(ShadowConfig.ShadowClientConfig)
}
