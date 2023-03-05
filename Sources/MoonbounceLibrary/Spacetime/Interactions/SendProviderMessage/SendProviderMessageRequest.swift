//
//  SendProviderMessageRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class SendProviderMessageRequest: Effect
{
    let message: Data

    public override var description: String
    {
        return "\(self.module).SendProviderMessageRequest[id: \(self.id), message: \(self.message)]"
    }

    public init(_ message: Data)
    {
        self.message = message

        super.init(module: VPNModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
        case message
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let message = try container.decode(Data.self, forKey: .message)

        self.message = message

        super.init(id: id, module: VPNModule.name)
    }
}
