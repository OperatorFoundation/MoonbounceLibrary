//
//  SendProviderMessageResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class SendProviderMessageResponse: Event
{
    let message: Data

    public override var description: String
    {
        return "\(self.module).SendProviderMessageResponse[effectID: \(String(describing: self.effectId)), message: \(self.message)]"
    }

    public init(_ effectId: UUID, _ message: Data)
    {
        self.message = message

        super.init(effectId, module: VPNModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
        case message
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let message = try container.decode(Data.self, forKey: .message)

        self.message = message

        super.init(effectId, module: VPNModule.name)
    }
}
