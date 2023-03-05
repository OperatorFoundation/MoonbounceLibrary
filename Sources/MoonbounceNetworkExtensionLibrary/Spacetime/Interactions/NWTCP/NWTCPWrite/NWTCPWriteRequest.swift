//
//  NWTCPWriteRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 2/4/22.
//

import Foundation

import Spacetime
import SwiftHexTools

public class NWTCPWriteRequest: Effect
{
    public let socketId: UUID
    public let data: Data
    public let lengthPrefixSizeInBits: Int?

    public override var description: String
    {
        return "\(self.module).NWTCPWriteRequest[id: \(self.id), socketId: \(self.socketId), data: \(self.data), lengthPrefixSizeInBits: \(String(describing: self.lengthPrefixSizeInBits))]"
    }

    public init(_ socketId: UUID, _ data: Data, _ lengthPrefixSizeInBits: Int? = nil)
    {
        self.socketId = socketId
        self.data = data
        self.lengthPrefixSizeInBits = lengthPrefixSizeInBits

        super.init(module: BuiltinModuleNames.networkConnect.rawValue)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
        case socketId
        case data
        case lengthPrefixSizeInBits
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let socketId = try container.decode(UUID.self, forKey: .socketId)
        let data = try container.decode(Data.self, forKey: .data)
        let lengthPrefixSizeInBits = try container.decode(Int?.self, forKey: .lengthPrefixSizeInBits)

        self.socketId = socketId
        self.data = data
        self.lengthPrefixSizeInBits = lengthPrefixSizeInBits

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}
