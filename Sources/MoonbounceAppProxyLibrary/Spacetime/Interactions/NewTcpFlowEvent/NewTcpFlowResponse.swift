//
//  NewTcpFlowResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class NewTcpFlowResponse: Event
{
    public override var description: String
    {
        return "\(self.module).NewTcpFlowResponse[effectID: \(String(describing: self.effectId))]"
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: AppProxyModule.name)
    }
}
