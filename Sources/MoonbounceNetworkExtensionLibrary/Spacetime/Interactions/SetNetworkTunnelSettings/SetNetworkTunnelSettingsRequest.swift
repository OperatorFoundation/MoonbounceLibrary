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

    public override var description: String
    {
        return "\(self.module).SetNetworkTunnelSettingsRequest[id: \(self.id), host: \(self.host), tunnelAddress: \(self.tunnelAddress)]"
    }

    public init(_ host: String, _ tunnelAddress: TunnelAddress)
    {
        self.host = host
        self.tunnelAddress = tunnelAddress

        super.init(module: NetworkExtensionModule.name)
    }
}

