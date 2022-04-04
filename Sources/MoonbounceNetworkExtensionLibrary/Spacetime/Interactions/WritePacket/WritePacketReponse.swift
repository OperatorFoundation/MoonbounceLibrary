//
//  WritePacketResponse.swift
//

import Foundation
import Spacetime

public class WritePacketResponse: Event
{
    public init(_ effectId: UUID)
    {
        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

