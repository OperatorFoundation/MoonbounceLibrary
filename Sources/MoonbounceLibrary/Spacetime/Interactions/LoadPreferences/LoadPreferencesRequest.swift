//
//  LoadPreferencesRequest.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class LoadPreferencesRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).LoadPreferencesRequest[id: \(self.id)]"
    }

    public init()
    {
        super.init(module: VPNModule.name)
    }
}
