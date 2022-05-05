//
//  NewTcpFlowEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class NewTcpFlowEvent: Event
{
    let uuid: UUID

    public override var description: String
    {
        return "\(self.module).NewTcpFlowEvent[uuid: \(self.uuid)]"
    }

    public init(uuid: UUID)
    {
        self.uuid = uuid

        super.init(module: AppProxyModule.name)
    }
}
