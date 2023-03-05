//
//  NWTCPWriteResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 2/4/22.
//

import Foundation

import Spacetime

public class NWTCPWriteResponse: Event
{
    public let socketId: UUID

    public override var description: String
    {
        return "\(self.module).NWTCPWriteResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID, _ socketId: UUID)
    {
        self.socketId = socketId

        super.init(effectId, module: BuiltinModuleNames.networkConnect.rawValue)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
        case socketId
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let socketId = try container.decode(UUID.self, forKey: .socketId)

        self.socketId = socketId

        super.init(effectId, module: BuiltinModuleNames.networkConnect.rawValue)
    }
}
