//
//  VPNModule.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Chord
import Foundation
import NetworkExtension

public class VPNModule
{
    static public let name = "VPN"
    
    public var logger: Logger
    var manager: NETunnelProviderManager? = nil

    public init(logger: Logger)
    {
        self.logger = logger
    }

    public func name() -> String
    {
        return VPNModule.name
    }
    
    func loadPreferences() throws -> VPNPreferences
    {
        let manager: NETunnelProviderManager
    
        print("✶ VPNModule loadPreferences called")
        if let actualManager = self.manager
        {
            print("✶ NETunnelProviderManager already exists")
            manager = actualManager
        }
        else
        {
            
            print("✶ Creating a new NETunnelProviderManager")
            manager = NETunnelProviderManager()

            let maybeError = MainThreadSynchronizer.sync(manager.loadFromPreferences)
            if let error = maybeError
            {
                print("✶ VPNModule.savePreferences - error: \(error)")
                throw error
            }
            
            print("✶ NETunnelProviderManager loaded: \(manager)")
            self.manager = manager
        }
        
        let description = manager.localizedDescription ?? "Moonbounce"
        let enabled = manager.isEnabled
        let protocolConfiguration = (manager.protocolConfiguration as? NETunnelProviderProtocol) ?? NETunnelProviderProtocol()
        if protocolConfiguration.providerBundleIdentifier == nil {
            protocolConfiguration.providerBundleIdentifier = ""
        }
        
        if protocolConfiguration.providerConfiguration == nil {
            protocolConfiguration.providerConfiguration = [:]
        }
        
        if protocolConfiguration.serverAddress == nil {
            protocolConfiguration.serverAddress = ""
        }
        
        manager.protocolConfiguration = protocolConfiguration
        
        let completePreferences = VPNPreferences(protocolConfiguration: protocolConfiguration, description: description, enabled: enabled)

        if let error = MainThreadSynchronizer.sync(manager.saveToPreferences)
        {
            print("✶ VPNModule.loadPreferences - error: \(error)")
        }
        
        return completePreferences
    }

    func savePreferences(_ preferences: VPNPreferences) throws
    {
        print("✶ VPNModule savePreferences() called")
        guard let manager = self.manager else
        {
            print("✶ VPNModule savePreferences failed to set manager")
            throw VPNModuleError.managerIsNil
        }
        print("✶ VPNModule savePreferences() manager: \(manager)")
        
        // FIXME: Need to give manager a protocolConfiguration (used to be in savePreferencesRequest)
        
        guard let protocolConfiguration = manager.protocolConfiguration else
        {
            print("✶ VPNModule savePreferences failed to set protocolConfiguration")
            throw VPNModuleError.protocolConfigurationIsNil
        }
        print("✶ VPNModule savePreferences() protocolConfiguration: \(protocolConfiguration)")

        guard let typedProtocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol else
        {
            print("✶ VPNModule savePreferences falied to set typedProtocolConfiguration")
            throw VPNModuleError.typedProtocolConfigurationIsNil
        }
        print("✶ VPNModule savePreferences() typedProtocolConfiguration: \(typedProtocolConfiguration)")

        typedProtocolConfiguration.providerBundleIdentifier = preferences.providerBundleIdentifier

        guard var providerConfiguration = typedProtocolConfiguration.providerConfiguration else
        {
            print("✶ VPNModule savePreferences falied to set providerConfiguration")
            throw VPNModuleError.providerConfigurationIsNil
        }
        
        print("✶ VPNModule savePreferences() providerConFiguration: \(providerConfiguration)")
        providerConfiguration["serverAddress"] = preferences.serverAddress
        typedProtocolConfiguration.serverAddress = preferences.serverAddress
        typedProtocolConfiguration.providerConfiguration = providerConfiguration

        manager.protocolConfiguration = typedProtocolConfiguration
        manager.localizedDescription = preferences.description
        manager.isEnabled = preferences.enabled

        if let error = MainThreadSynchronizer.sync(manager.saveToPreferences)
        {
            print("✶ VPNModule.savePreferences - error: \(error)")
            throw error
        }
    }

    func enable() throws
    {
        print("✶ VPNModule enable called")
        guard let manager = self.manager else
        {
            print("✶ Failed to enable the VPNModule, the NETunnelProviderManager is nil.")
            throw VPNModuleError.managerIsNil
        }

        manager.isEnabled = true
        
        if let error = MainThreadSynchronizer.sync(manager.loadFromPreferences)
        {
            print("✶ VPNModule.enable - loadFromPreferences error: \(error)")
            throw error
        }
        
        if let error = MainThreadSynchronizer.sync(manager.saveToPreferences)
        {
            print("✶ VPNModule.enable - saveToPreferences error: \(error)")
            throw error
        }

        // https://stackoverflow.com/questions/47550706/error-domain-nevpnerrordomain-code-1-null-while-connecting-vpn-server
        if let error = MainThreadSynchronizer.sync(manager.loadFromPreferences)
        {
            print("✶ VPNModule.enable - loadFromPreferences error: \(error)")
            throw error
        }

        do
        {
            try manager.connection.startVPNTunnel()
            print("✶ VPNModule.enable complete.")
        }
        catch
        {
            print("✶ VPNModule.enable - startVPNTunnel error: \(error)")
            throw error
        }
    }

    func disable() throws
    {
        print("✶ VPNModule.disable called.")
        
        guard let manager = self.manager else
        {
            throw VPNModuleError.managerIsNil
        }

        manager.isEnabled = false

        if let error = MainThreadSynchronizer.sync(manager.saveToPreferences)
        {
            print("✶ VPNModule.disable - error: \(error)")
            throw error
        }
    }

    func connectionStatus() throws -> NEVPNStatus
    {
        guard let manager = self.manager else
        {
            throw VPNModuleError.managerIsNil
        }

        guard let session = manager.connection as? NETunnelProviderSession else
        {
            throw VPNModuleError.managerConnectionIsWrongType
        }
        
        print("✶ VPNModule.connectionStatus: \(session.status)")
        return session.status
    }

    func sendProviderMessage(_ data: Data) throws -> Data
    {
        guard let manager = self.manager else
        {
            throw VPNModuleError.managerIsNil
        }

        guard let session = manager.connection as? NETunnelProviderSession else
        {
            throw VPNModuleError.managerConnectionIsWrongType
        }


        guard let response = try Synchronizer.syncThrows({completion in return try session.sendProviderMessage(data, responseHandler: completion)}) else
        {
            throw VPNModuleError.providerMessageResponseIsNil
        }
        
        print("✶ VPNModule.sendProviderMessage returning: \(response.string)")
        return response
    }
}

public enum VPNModuleError: Error {
    case managerIsNil
    case protocolConfigurationIsNil
    case typedProtocolConfigurationIsNil
    case providerConfigurationIsNil
    case managerConnectionIsWrongType
    case providerMessageResponseIsNil
}
