//
//  ReadPacketResponse.swift
//

import Foundation
import Spacetime

public class ReadPacketResponse: Event
{
    let data: Data

    public init(_ effectId: UUID, _ data: Data)
    {
        self.data = data

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

