//
//  EnableResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class EnableResponse: Event
{
    public override var description: String
    {
        return "\(self.module).EnableResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: VPNModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)

        super.init(effectId, module: VPNModule.name)
    }
}
