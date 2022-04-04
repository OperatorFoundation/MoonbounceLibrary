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
    public init()
    {
        super.init(module: VPNModule.name)
    }
}
