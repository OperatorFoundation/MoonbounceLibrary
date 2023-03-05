//
//  GetConfigurationRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class GetConfigurationRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).GetConfigurationRequest[id: \(self.id)]"
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
