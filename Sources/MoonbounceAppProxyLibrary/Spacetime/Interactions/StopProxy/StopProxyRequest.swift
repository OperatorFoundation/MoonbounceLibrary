//
//  StopTunnelRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StopProxyRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).StopProxyRequest[id: \(self.id)]"
    }

    public init()
    {
        super.init(module: AppProxyModule.name)
    }
}
