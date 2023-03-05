//
//  ReadPacketRequest.swift
//

import Foundation
import Spacetime

public class ReadPacketRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).ReadPacketRequest[id: \(self.id)]"
    }

    public init()
    {
        super.init(module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}

