//
//  ReadPacketRequest.swift
//

import Foundation
import Spacetime

public class ReadPacketRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).ReadPacketRequest[id: \(self.id)]"
    }

    public init()
    {
        super.init(module: NetworkExtensionModule.name)
    }
}

