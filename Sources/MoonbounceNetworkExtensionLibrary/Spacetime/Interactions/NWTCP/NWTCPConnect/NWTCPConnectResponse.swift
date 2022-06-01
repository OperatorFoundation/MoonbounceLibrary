//
//  NWTCPConnectResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class NWTCPConnectResponse: Event
{
    public let socketId: UUID

    public override var description: String
    {
        return "\(self.module).NWTCPConnectResponse[effectID: \(String(describing: self.effectId)), socketId: \(self.socketId)]"
    }

    public init(_ effectId: UUID, socketId: UUID)
    {
        self.socketId = socketId

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}
