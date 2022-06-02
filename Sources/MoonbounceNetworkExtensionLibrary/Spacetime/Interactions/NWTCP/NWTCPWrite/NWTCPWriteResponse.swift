//
//  NWTCPWriteResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 2/4/22.
//

import Foundation

import Spacetime

public class NWTCPWriteResponse: Event
{
    public let socketId: UUID

    public override var description: String
    {
        return "\(self.module).NWTCPWriteResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID, _ socketId: UUID)
    {
        self.socketId = socketId

        super.init(effectId, module: BuiltinModuleNames.networkConnect.rawValue)
    }
}
