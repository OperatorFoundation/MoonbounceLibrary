//
//  StopTunnelResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime
import NetworkExtension

public class StopTunnelResponse: Event
{
    public override var description: String
    {
        return "\(self.module).StopTunnelResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: NetworkExtensionModule.name)
    }
}
