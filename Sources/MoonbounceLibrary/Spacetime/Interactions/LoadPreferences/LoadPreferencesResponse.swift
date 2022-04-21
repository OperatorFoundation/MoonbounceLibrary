//
//  LoadPreferencesResponse.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class LoadPreferencesResponse: Event
{
    let preferences: VPNPreferences

    public override var description: String
    {
        return "\(self.module).LoadPreferencesResponse[effectID: \(String(describing: self.effectId)), preferences: \(self.preferences)]"
    }

    public init(_ effectId: UUID, _ preferences: VPNPreferences)
    {
        self.preferences = preferences
        
        super.init(effectId, module: VPNModule.name)
    }
}
