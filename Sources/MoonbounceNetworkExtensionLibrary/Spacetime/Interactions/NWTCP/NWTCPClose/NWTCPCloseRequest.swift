//
//  NWTCPCloseRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension

import Spacetime

public class NWTCPCloseRequest: Effect
{
    let socketId: UUID

    public override var description: String
    {
        return "\(self.module).NWTCPCloseRequest[id: \(self.id), socketId: \(self.socketId)]"
    }

    public init(_ socketId: UUID)
    {
        self.socketId = socketId

        super.init(module: NetworkExtensionModule.name)
    }
}
