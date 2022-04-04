//
//  SetNetworkTunnelSettingsRequest.swift
//

import Foundation
import NetworkExtension
import Spacetime

public class SetNetworkTunnelSettingsRequest: Effect
{
    public let host: String
    public let tunnelAddress: TunnelAddress

    public init(_ host: String, _ tunnelAddress: TunnelAddress)
    {
        self.host = host
        self.tunnelAddress = tunnelAddress

        super.init(module: NetworkExtensionModule.name)
    }
}

