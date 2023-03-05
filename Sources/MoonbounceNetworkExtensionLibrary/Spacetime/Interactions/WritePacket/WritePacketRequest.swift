//
//  WritePacketRequest.swift
//

import Foundation
import Spacetime

public class WritePacketRequest: Effect
{
    public let data: Data

    public override var description: String
    {
        return "\(self.module).WritePacketRequest[id: \(self.id), data: \(self.data)]"
    }

    public init(_ data: Data)
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
        let data = try container.decode(Data.self, forKey: .data)

        self.data = data

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}

