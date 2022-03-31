//
//  VPNPreferencesController.swift
//  Moonbounce
//
//  Created by Mafalda on 4/14/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Foundation
import Logging
import MoonbounceShared
import TunnelClient

/// All of these functions must be called from the main thread
public class VPNPreferencesController
{
    public var maybeVPNPreference: NETunnelProviderManager?

    let logger: Logger

    public init(logger: Logger)
    {
        self.logger = logger
    }
    
    // MARK: Public Functions
    public func setup(moonbounceConfig: MoonbounceConfig, completionHandler: @escaping ((Either<NETunnelProviderManager>) -> Void))
    {
        // Doing this because we believe NetworkExtension requires it
        logger.debug("VPNPreferencesController.setup, loading...")

        load
        {
           (eitherVPNPreference) in

            self.logger.debug("VPNPreferencesController.setup, loaded.")

            switch eitherVPNPreference
            {
                case .error(_):
                    completionHandler(eitherVPNPreference)
                    return
                case .value(let vpnPreference):
                    self.updateConfiguration(moonbounceConfig: moonbounceConfig)
                    {
                        (maybeError) in

                        if let error = maybeError
                        {
                            completionHandler(Either<NETunnelProviderManager>.error(error))
                            return
                        }
                        else
                        {
                            completionHandler(Either<NETunnelProviderManager>.value(vpnPreference))
                            return
                        }

                    }
            }
        }
    }
    
    public func updateConfiguration(moonbounceConfig: MoonbounceConfig, isEnabled: Bool = false, completionHandler: @escaping ((Error?) -> Void))
    {
        logger.debug("VPNPreferencesController.updateConfiguration 1")

        if let vpnPreference = maybeVPNPreference
        {
            updateConfiguration(vpnPreference: vpnPreference, moonbounceConfig: moonbounceConfig, completionHandler: completionHandler)
        }
        else
        {
            setup(moonbounceConfig: moonbounceConfig)
            {
                (eitherVPNPreference) in
                
                switch eitherVPNPreference
                {
                    case .error(let error):
                        completionHandler(error)
                        return
                    case .value(let vpnPreference):
                        self.maybeVPNPreference = vpnPreference
                        self.updateConfiguration(vpnPreference: vpnPreference, moonbounceConfig: moonbounceConfig, completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func updateConfiguration(vpnPreference: NETunnelProviderManager, moonbounceConfig: MoonbounceConfig, isEnabled: Bool = true, completionHandler: @escaping ((Error?) -> Void))
    {
        logger.debug("VPNPreferencesController.updateConfiguration 2")

        guard let protocolConfiguration = self.newProtocolConfiguration(moonbounceConfig: moonbounceConfig)
        else
        {
            completionHandler(VPNPreferencesError.protocolConfiguration)
            return
        }
        
        vpnPreference.protocolConfiguration = protocolConfiguration
        vpnPreference.localizedDescription = moonbounceConfig.name
        vpnPreference.isEnabled = isEnabled
        
        self.save(completionHandler: completionHandler)
    }
    
    public func deactivate(completionHandler: @escaping ((Error?) -> Void))
    {
        logger.debug("VPNPreferencesController.deactivate")

        if let vpnPreference = maybeVPNPreference
        {
            vpnPreference.isEnabled = false
            save(vpnPreference: vpnPreference, completionHandler: completionHandler)
        }
        else
        {
            completionHandler(VPNPreferencesError.nilVPNPreference)
        }
    }

    public func load(completionHandler: @escaping ((Either<NETunnelProviderManager>) -> Void))
    {
        logger.debug("VPNPreferencesController.load")

        let newManager = NETunnelProviderManager()

         newManager.loadFromPreferences
         {
             (maybeError) in
         
             if let error = maybeError
             {
                 appLog.error("\nError loading from preferences!\(error)\n")
                
                self.maybeVPNPreference = nil
                completionHandler(.error(error))
                return
             }
            
            self.maybeVPNPreference = newManager
            completionHandler(.value(newManager))
            return
        }
    }
    
    public func save(completionHandler: @escaping ((Error?) -> Void))
    {
        logger.debug("VPNPreferencesController.save 1")

        guard let vpnPreference = maybeVPNPreference else
        {
            completionHandler(VPNPreferencesError.nilVPNPreference)
            return
        }
        
        save(vpnPreference: vpnPreference, completionHandler: completionHandler)
    }
    
    public func save(vpnPreference: NETunnelProviderManager, completionHandler: @escaping ((Error?) -> Void))
    {
        logger.debug("VPNPreferencesController.save 2")

        vpnPreference.saveToPreferences
        {
            maybeError in
            
            guard maybeError == nil else
            {
                appLog.error("\nFailed to save the configuration: \(maybeError!)\n")
                completionHandler(maybeError)
                return
            }
            
            vpnPreference.loadFromPreferences(completionHandler:
            {
                (maybeError) in
                
                if let error = maybeError
                {
                    appLog.error("\nError loading from preferences!\(error)\n")
                    completionHandler(error)
                    return
                }
                
                completionHandler(nil)
            })
        }
    }
    
    public func newProtocolConfiguration(moonbounceConfig: MoonbounceConfig) -> NETunnelProviderProtocol?
    {
        logger.debug("VPNPreferencesController.newProtocolConfiguration")

        let protocolConfiguration: NETunnelProviderProtocol = NETunnelProviderProtocol()
        let appId = Bundle.main.bundleIdentifier!
        appLog.debug("\n----->Setting the providerBundleIdentifier to \(appId).NetworkExtension")
        protocolConfiguration.providerBundleIdentifier = "\(appId).NetworkExtension"
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
                        Keys.tunnelNameKey.rawValue: moonbounceConfig.name]
                
        return protocolConfiguration
    }
}

public enum VPNPreferencesError: Error
{
    case protocolConfiguration
    case nilVPNPreference
    case unexpectedNilValue
    
    var localizedDescription: String
    {
        switch self
        {
            case .protocolConfiguration:
                return NSLocalizedString("Failed to initialize a NETunnelProviderProtocol", comment: "")
            case .nilVPNPreference:
                return NSLocalizedString("Cannot save a nil preference.", comment: "")
            case .unexpectedNilValue:
                return NSLocalizedString("We got a nil value that should be impossible.", comment: "")
        }
    }
}

public enum Either<Value>
{
    case value(Value)
    case error(Error)
}


