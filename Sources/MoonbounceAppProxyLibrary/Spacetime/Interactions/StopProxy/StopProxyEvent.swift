//
//  StopTunnelEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime
import NetworkExtension

public class StopProxyEvent: Event
{
    let reason: NEProviderStopReason

    public override var description: String
    {
        return "\(self.module).StopProxyEvent[reason: \(self.reason)]"
    }

    public init(_ reason: NEProviderStopReason)
    {
        self.reason = reason

        super.init(module: AppProxyModule.name)
    }
}
