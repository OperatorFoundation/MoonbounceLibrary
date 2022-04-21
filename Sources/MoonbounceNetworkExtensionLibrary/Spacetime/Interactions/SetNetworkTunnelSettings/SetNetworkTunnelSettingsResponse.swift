//
//  SetNetworkTunnelSettingsResponse.swift
//

import Foundation
import Spacetime

public class SetNetworkTunnelSettingsResponse: Event
{
    public override var description: String
    {
        return "\(self.module).SetNetworkTunnelSettingsResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

