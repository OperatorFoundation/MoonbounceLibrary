//
//  ConnectionStatusRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class ConnectionStatusRequest: Effect
{
    public init()
    {
        super.init(module: VPNModule.name)
    }
}
