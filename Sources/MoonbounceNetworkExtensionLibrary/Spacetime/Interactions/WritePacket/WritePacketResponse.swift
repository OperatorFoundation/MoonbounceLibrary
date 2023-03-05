//
//  WritePacketResponse.swift
//

import Foundation
import Spacetime

public class WritePacketResponse: Event
{
    public override var description: String
    {
        return "\(self.module).WritePacketResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

