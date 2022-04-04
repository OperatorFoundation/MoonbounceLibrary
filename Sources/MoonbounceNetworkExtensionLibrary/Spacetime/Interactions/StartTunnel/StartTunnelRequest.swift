//
//  StartTunnelRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StartTunnelRequest: Effect
{
    let maybeError: Error?

    public init(_ maybeError: Error?)
    {
        self.maybeError = maybeError

        super.init(module: NetworkExtensionModule.name)
    }
}
