//
//  GetConfigurationResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class GetConfigurationResponse: Event
{
    let configuration: String

    public override var description: String
    {
        return "\(self.module).GetConfigurationResponse[effectID: \(String(describing: self.effectId)), configuration: \(self.configuration)]"
    }

    public init(_ effectId: UUID, _ configuration: String)
    {
        self.configuration = configuration

        super.init(effectId, module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
        case configuration
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let configuration = try container.decode(String.self, forKey: .configuration)

        self.configuration = configuration

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}
