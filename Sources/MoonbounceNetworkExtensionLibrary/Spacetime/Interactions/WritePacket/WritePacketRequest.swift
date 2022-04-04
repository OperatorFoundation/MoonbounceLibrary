//
//  WritePacketRequest.swift
//

import Foundation
import Spacetime

public class WritePacketRequest: Effect
{
    public let data: Data

    public init(_ data: Data)
    {
        self.data = data

        super.init(module: NetworkExtensionModule.name)
    }
}

