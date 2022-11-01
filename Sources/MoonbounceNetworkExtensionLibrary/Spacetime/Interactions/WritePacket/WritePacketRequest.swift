//
//  WritePacketRequest.swift
//

import Foundation
import Spacetime

public class WritePacketRequest: Effect
{
    public let data: Data

    public override var description: String
    {
        return "\(self.module).WritePacketRequest[id: \(self.id), data: \(self.data)]"
    }

    public init(_ data: Data)
    {
        self.data = data

        super.init(module: NetworkExtensionModule.name)
    }
}

