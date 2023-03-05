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

    public enum CodingKeys: String, CodingKey
    {
        case id
        case host
        case tunnelAddress
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let host = try container.decode(String.self, forKey: .host)
        let tunnelAddress = try container.decode(TunnelAddress.self, forKey: .tunnelAddress)

        self.host = host
        self.tunnelAddress = tunnelAddress

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}

