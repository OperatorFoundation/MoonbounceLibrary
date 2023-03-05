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

    public enum CodingKeys: String, CodingKey
    {
        case id
        case host
        case port
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let host = try container.decode(String.self, forKey: .host)
        let port = try container.decode(Int.self, forKey: .port)

        self.host = host
        self.port = port

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}
