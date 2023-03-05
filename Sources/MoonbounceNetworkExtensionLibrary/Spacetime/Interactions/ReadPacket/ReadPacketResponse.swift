//
//  ReadPacketResponse.swift
//

import Foundation
import Spacetime

public class ReadPacketResponse: Event
{
    let data: Data

    public override var description: String
    {
        return "\(self.module).ReadPacketResponse[effectID: \(String(describing: self.effectId)), data: \(self.data)]"
    }

    public init(_ effectId: UUID, _ data: Data)
    {
        self.data = data

        super.init(effectId, module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
        case data
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let data = try container.decode(Data.self, forKey: .data)

        self.data = data

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

