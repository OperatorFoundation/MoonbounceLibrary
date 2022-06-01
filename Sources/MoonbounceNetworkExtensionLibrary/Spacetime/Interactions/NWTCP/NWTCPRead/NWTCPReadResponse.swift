//
//  NWTCPReadResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 2/4/22.
//

import Foundation

import Spacetime

public class NWTCPReadResponse: Event
{
    public let socketId: UUID
    public let data: Data

    public override var description: String
    {
        return "\(self.module).NWTCPReadResponse[effectID: \(String(describing: self.effectId)), data: \(self.data)]"
    }

    public init(_ effectId: UUID, _ socketId: UUID, _ data: Data)
    {
        self.socketId = socketId
        self.data = data

        super.init(effectId, module: BuiltinModuleNames.networkConnect.rawValue)
    }
}
