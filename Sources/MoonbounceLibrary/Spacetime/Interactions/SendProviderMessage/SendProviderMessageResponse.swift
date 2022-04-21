//
//  SendProviderMessageResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class SendProviderMessageResponse: Event
{
    let message: Data

    public override var description: String
    {
        return "\(self.module).SendProviderMessageResponse[effectID: \(String(describing: self.effectId)), message: \(self.message)]"
    }

    public init(_ effectId: UUID, _ message: Data)
    {
        self.message = message

        super.init(effectId, module: VPNModule.name)
    }
}
