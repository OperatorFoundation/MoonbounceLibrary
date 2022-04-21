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

    public init(_ preferences: VPNPreferences)
    {
        self.preferences = preferences

        super.init(module: VPNModule.name)
    }
}
