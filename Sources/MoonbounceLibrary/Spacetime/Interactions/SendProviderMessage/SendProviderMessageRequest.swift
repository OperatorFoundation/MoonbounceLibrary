//
//  SendProviderMessageRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class SendProviderMessageRequest: Effect
{
    let message: Data

    public override var description: String
    {
        return "\(self.module).SendProviderMessageRequest[id: \(self.id), message: \(self.message)]"
    }

    public init(_ message: Data)
    {
        self.message = message

        super.init(module: VPNModule.name)
    }
}
