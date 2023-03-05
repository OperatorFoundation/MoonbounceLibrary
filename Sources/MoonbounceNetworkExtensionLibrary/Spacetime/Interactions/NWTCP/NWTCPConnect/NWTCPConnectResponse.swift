//
//  NWTCPConnectResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class NWTCPConnectResponse: Event
{
    public let socketId: UUID

    public override var description: String
    {
        return "\(self.module).NWTCPConnectResponse[effectID: \(String(describing: self.effectId)), socketId: \(self.socketId)]"
    }

    public init(_ effectId: UUID, socketId: UUID)
    {
        self.socketId = socketId

        super.init(effectId, module: NetworkExtensionModule.name)
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

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}
