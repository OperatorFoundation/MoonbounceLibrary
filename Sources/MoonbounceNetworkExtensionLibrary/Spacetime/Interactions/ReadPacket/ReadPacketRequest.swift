//
//  ReadPacketRequest.swift
//

import Foundation
import Spacetime

public class ReadPacketRequest: Effect
{
    public init()
    {
        super.init(module: NetworkExtensionModule.name)
    }
}

