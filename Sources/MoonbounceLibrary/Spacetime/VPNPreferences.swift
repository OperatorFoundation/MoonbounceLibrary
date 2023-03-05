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
    let serverAddress: String
    let providerBundleIdentifier: String
    let description: String
    let enabled: Bool

    public init(protocolConfiguration: NETunnelProviderProtocol, description: String, enabled: Bool)
    {
        self.serverAddress = protocolConfiguration.providerConfiguration!["serverAddress"]! as! String
        self.providerBundleIdentifier = protocolConfiguration.providerBundleIdentifier!
        self.description = description
        self.enabled = enabled
    }
}
