//
//  StopTunnelEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime
import NetworkExtension

public class StopTunnelEvent: Event
{
    let reason: NEProviderStopReason

    public override var description: String
    {
        return "\(self.module).StopTunnelEvent[reason: \(self.reason)]"
    }

    public init(_ reason: NEProviderStopReason)
    {
        self.reason = reason

        super.init(module: NetworkExtensionModule.name)
    }
}
