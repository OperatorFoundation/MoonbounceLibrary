//
//  NWTCPReadRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 2/4/22.
//

import Foundation

import Spacetime

public class NWTCPReadRequest: Effect
{
    public let socketId: UUID
    public let style: NetworkConnectReadStyle

    public override var description: String
    {
        return "\(self.module).NWTCPReadRequest[id: \(self.id), socketId: \(self.socketId), style: \(self.style)]"
    }

    public init(_ socketId: UUID, _ style: NetworkConnectReadStyle)
    {
        self.socketId = socketId
        self.style = style

        super.init(module: BuiltinModuleNames.networkConnect.rawValue)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
        case socketId
        case style
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let socketId = try container.decode(UUID.self, forKey: .socketId)
        let style = try container.decode(NetworkConnectReadStyle.self, forKey: .style)

        self.socketId = socketId
        self.style = style

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}
