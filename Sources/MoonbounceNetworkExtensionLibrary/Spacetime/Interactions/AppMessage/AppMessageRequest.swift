//
//  AppMessageRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class AppMessageRequest: Effect
{
    let data: Data?

    public override var description: String
    {
        if let someData = data
        {
            return "\(self.module).SendProviderMessageRequest[id: \(self.id), data: \(someData)]"
        }
        else
        {
            return "\(self.module).SendProviderMessageRequest[id: \(self.id), data: nil]"
        }
    }

    public init(_ data: Data?)
    {
        self.data = data

        super.init(module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
        case data
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let data = try container.decode(Data?.self, forKey: .data)

        self.data = data

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}
