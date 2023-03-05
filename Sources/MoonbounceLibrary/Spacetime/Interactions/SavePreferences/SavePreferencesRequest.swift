//
//  SavePreferencesRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class SavePreferencesRequest: Effect
{
    let preferences: VPNPreferences

    public override var description: String
    {
        return "\(self.module).SavePreferencesRequest[id: \(self.id), preferences: \(self.preferences)]"
    }

    public init(_ id: UUID, _ preferences: VPNPreferences)
    {
        self.preferences = preferences

        super.init(id: id, module: VPNModule.name)
    }

    public init(_ preferences: VPNPreferences)
    {
        self.preferences = preferences

        super.init(module: VPNModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
        case preferences
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let preferences = try container.decode(VPNPreferences.self, forKey: .preferences)

        self.preferences = preferences

        super.init(id: id, module: VPNModule.name)
    }
}
