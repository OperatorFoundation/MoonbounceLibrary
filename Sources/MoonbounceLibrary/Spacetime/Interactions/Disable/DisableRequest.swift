//
//  DisableRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class DisableRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).DisableRequest[id: \(self.id)]"
    }

    public init()
    {
        super.init(module: VPNModule.name)
    }
}
