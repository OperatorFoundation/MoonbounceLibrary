//
//  NWTCPReadRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 2/4/22.
//

import Foundation

import Spacetime

public class NWTCPReadRequest: Effect
{
    public let socketId: UUID
    public let style: NetworkConnectReadStyle

    public override var description: String
    {
        return "\(self.module).NWTCPReadRequest[id: \(self.id), socketId: \(self.socketId), style: \(self.style)]"
    }

    public init(_ socketId: UUID, _ style: NetworkConnectReadStyle)
    {
        self.socketId = socketId
        self.style = style

        super.init(module: BuiltinModuleNames.networkConnect.rawValue)
    }
}
