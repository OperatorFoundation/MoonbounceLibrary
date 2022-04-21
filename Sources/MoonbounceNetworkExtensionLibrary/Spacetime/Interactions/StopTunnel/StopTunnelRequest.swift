//
//  StopTunnelRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StopTunnelRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).StopTunnelRequest[id: \(self.id)]"
    }

    public init()
    {
        super.init(module: NetworkExtensionModule.name)
    }
}
