//
//  EnableResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class EnableResponse: Event
{
    public override var description: String
    {
        return "\(self.module).EnableResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: VPNModule.name)
    }
}
