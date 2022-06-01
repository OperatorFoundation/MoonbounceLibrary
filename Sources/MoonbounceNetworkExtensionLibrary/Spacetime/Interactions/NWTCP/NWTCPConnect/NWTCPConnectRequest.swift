//
//  NWTCPConnectRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension

import Spacetime

public class NWTCPConnectRequest: Effect
{
    let host: String
    let port: Int

    public override var description: String
    {
        return "\(self.module).NWTCPConnectRequest[id: \(self.id), host: \(self.host), port: \(self.port)]"
    }

    public init(_ host: String, _ port: Int)
    {
        self.host = host
        self.port = port

        super.init(module: NetworkExtensionModule.name)
    }
}
