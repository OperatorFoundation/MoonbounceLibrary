//
//  configController.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 1/18/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
import MoonbounceShared
//import ReplicantSwift
import TunnelClient

// FIXME: replace applogs with actual logs
public class NetworkExtensionConfigController
{
    public static func getMoonbounceConfig(fromProtocolConfiguration protocolConfiguration: TunnelProviderProtocol) -> MoonbounceConfig?
    {
        guard let providerConfiguration = protocolConfiguration.providerConfiguration
            else
        {
            // appLog.error("\nAttempted to initialize a tunnel with a protocol config that does not have a provider config (no replicant or client configs).")
            return nil
        }

        guard let replicantConfigJSON = providerConfiguration[Keys.replicantConfigKey.rawValue] as? Data
        else
        {
            appLog.error("unable to load replicant config from provider configuration")
            return nil
        }
        
//        guard let replicantConfig = ReplicantConfig(from: replicantConfigJSON)
//            else
//        {
//            return nil
//        }
        
//        guard let clientConfigJSON = providerConfiguration[Keys.clientConfigKey.rawValue] as? Data
//            else
//        {
//            // appLog.error("Unable to get ClientConfig JSON from provider config")
//            return nil
//        }
        
//        guard let clientConfig = ClientConfig.parse(jsonData: clientConfigJSON)
//            else
//        {
//            return nil
//        }
        
        guard let name = providerConfiguration[Keys.tunnelNameKey.rawValue] as? String
        else
        {
            // appLog.error("Unable to get tunnel name from provider config.")
            return nil
        }
        
        let moonbounceConfig = MoonbounceConfig(name: name/*, replicantConfig: replicantConfig*/)
        
        return moonbounceConfig
    }
    
}
