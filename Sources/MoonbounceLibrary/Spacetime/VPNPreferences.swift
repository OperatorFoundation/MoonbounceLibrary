//
//  VPNPreferences.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension

public struct VPNPreferences: Codable
{
    var serverAddress: String? = nil
    var providerBundleIdentifier: String? = nil
    let description: String
    let enabled: Bool

    public init(protocolConfiguration: NETunnelProviderProtocol, description: String, enabled: Bool)
    {
        self.description = description
        self.enabled = enabled
        self.providerBundleIdentifier = protocolConfiguration.providerBundleIdentifier
        
        guard let providerConfiguration = protocolConfiguration.providerConfiguration else
        {
            return
        }
        
        guard let serverAddressAny = providerConfiguration["serverAddress"] else
        {
            return
        }
            
        guard let serverAddressString = serverAddressAny as? String else
        {
            return
        }
        
        self.serverAddress = serverAddressString
    }
}
