//
//  SetNetworkTunnelSettingsResponse.swift
//

import Foundation
import Spacetime

public class SetNetworkTunnelSettingsResponse: Event
{
    public init(_ effectId: UUID)
    {
        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

