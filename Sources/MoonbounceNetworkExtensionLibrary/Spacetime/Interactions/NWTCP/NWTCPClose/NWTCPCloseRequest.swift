//
//  NWTCPCloseRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension

import Spacetime

public class NWTCPCloseRequest: Effect
{
    let socketId: UUID

    public override var description: String
    {
        return "\(self.module).NWTCPCloseRequest[id: \(self.id), socketId: \(self.socketId)]"
    }

    public init(_ socketId: UUID)
    {
        self.socketId = socketId

        super.init(module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
        case socketId
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let socketId = try container.decode(UUID.self, forKey: .socketId)

        self.socketId = socketId

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}
