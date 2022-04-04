//
//  VPNPreferences.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension

public struct VPNPreferences
{
    let protocolConfiguration: NETunnelProviderProtocol
    let description: String
    let enabled: Bool

    public init(protocolConfiguration: NETunnelProviderProtocol, description: String, enabled: Bool)
    {
        self.protocolConfiguration = protocolConfiguration
        self.description = description
        self.enabled = enabled
    }
}
