//
//  WritePacketResponse.swift
//

import Foundation
import Spacetime

public class WritePacketResponse: Event
{
    public override var description: String
    {
        return "\(self.module).WritePacketResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

