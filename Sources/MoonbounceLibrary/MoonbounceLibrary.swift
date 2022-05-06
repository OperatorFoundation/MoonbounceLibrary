//
//  MoonbounceLibrary.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Logging
import Simulation
import Spacetime
import NetworkExtension
import Universe
import MoonbounceShared

public class MoonbounceLibrary
{
    let logger = Logger(label: "org.OperatorFoundation.Moonbounce.MacOS")
    let simulation: Simulation
    let universe: MoonbounceUniverse

    public init()
    {
        let vpnModule = VPNModule()
        self.simulation = Simulation(capabilities: Capabilities(BuiltinModuleNames.display.rawValue, VPNModule.name), userModules: [vpnModule])
        self.universe = MoonbounceUniverse(effects: self.simulation.effects, events: self.simulation.events, logger: self.logger)
    }

    public func configure(_ config: MoonbounceConfig) throws
    {
        let _ = try? self.universe.loadPreferences()

        guard let preferences = newProtocolConfiguration(moonbounceConfig: config) else
        {
            throw MoonbounceLibraryError.badConfig(config)
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

    func newProtocolConfiguration(moonbounceConfig: MoonbounceConfig) -> VPNPreferences?
    {
        self.logger.debug("VPNPreferencesController.newProtocolConfiguration")

        let protocolConfiguration: NETunnelProviderProtocol = NETunnelProviderProtocol()
        let appId = Bundle.main.bundleIdentifier!
        self.logger.debug("\n----->Setting the providerBundleIdentifier to \(appId).\(moonbounceConfig.providerBundleIdentifier)")
        protocolConfiguration.providerBundleIdentifier = "\(appId).\(moonbounceConfig.providerBundleIdentifier)"
        //        protocolConfiguration.serverAddress = "\(moonbounceConfig.replicantConfig?.serverIP)"
        protocolConfiguration.serverAddress = "127.0.0.1"
        protocolConfiguration.includeAllNetworks = true

        // FIXME: Replicant JSON needed here

        //        if moonbounceConfig.replicantConfig != nil
        //        {
        //            guard let replicantConfigJSON = moonbounceConfig.replicantConfig!.createJSON()
        //                else
        //            {
        //                return nil
        //            }
        //
        //            protocolConfiguration.providerConfiguration = [
        //                Keys.clientConfigKey.rawValue: clientConfigJSON,
        //                Keys.replicantConfigKey.rawValue: replicantConfigJSON,
        //                Keys.tunnelNameKey.rawValue: moonbounceConfig.name]
        //
        //            appLog.debug("\nproviderConfiguration: \(protocolConfiguration.providerConfiguration!)\n")
        //        }
        //        else
        //        {
        //            protocolConfiguration.providerConfiguration = [Keys.clientConfigKey.rawValue: clientConfigJSON]
        //        }

        let replicantConfigString = "{}"
        protocolConfiguration.providerConfiguration = [
            Keys.replicantConfigKey.rawValue: replicantConfigString.data,
            Keys.tunnelNameKey.rawValue: moonbounceConfig.name
        ]

        self.logger.info("newProtocolConfiguration: \(String(describing: protocolConfiguration.providerConfiguration))")

        let preferences = VPNPreferences(protocolConfiguration: protocolConfiguration, description: "Moonbounce", enabled: true)

        return preferences
    }
}

public enum MoonbounceLibraryError: Error
{
    case badConfig(MoonbounceConfig)
}
