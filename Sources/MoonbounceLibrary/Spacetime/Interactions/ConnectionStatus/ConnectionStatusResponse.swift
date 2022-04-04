//
//  ConnectionStatusResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class ConnectionStatusResponse: Event
{
    let status: NEVPNStatus

    public init(_ effectId: UUID, _ status: NEVPNStatus)
    {
        self.status = status
        
        super.init(effectId, module: VPNModule.name)
    }
}
