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

    public init(_ preferences: VPNPreferences)
    {
        self.preferences = preferences

        super.init(module: VPNModule.name)
    }
}
