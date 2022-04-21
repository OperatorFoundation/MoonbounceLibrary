//
//  ReadPacketResponse.swift
//

import Foundation
import Spacetime

public class ReadPacketResponse: Event
{
    let data: Data

    public override var description: String
    {
        return "\(self.module).ReadPacketResponse[effectID: \(String(describing: self.effectId)), data: \(self.data)]"
    }

    public init(_ effectId: UUID, _ data: Data)
    {
        self.data = data

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

