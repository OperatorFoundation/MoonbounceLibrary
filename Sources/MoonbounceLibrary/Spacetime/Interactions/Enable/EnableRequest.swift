//
//  EnableRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class EnableRequest: Effect
{
    public override var description: String
    {
        return "\(self.module).EnableRequest[id: \(self.id)]"
    }

    public init()
    {
        super.init(module: VPNModule.name)
    }
}
