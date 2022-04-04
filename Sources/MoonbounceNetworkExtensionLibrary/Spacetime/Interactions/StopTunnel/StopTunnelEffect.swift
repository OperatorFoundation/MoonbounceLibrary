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
    public init()
    {
        super.init(module: NetworkExtensionModule.name)
    }
}
