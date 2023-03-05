//
//  StartTunnelEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StartTunnelEvent: Event
{
    // FIXME - no way to make this Codable. Do we actually use this?
    // let options: [String : NSObject]?

    public override var description: String
    {
        return "\(self.module).StartTunnelEvent"
    }

    public init()
    {
        super.init(module: NetworkExtensionModule.name)
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
