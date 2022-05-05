//
//  NewUdpFlowRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class NewUdpFlowRequest: Effect
{
    let uuid: UUID
    let willHandle: Bool

    public override var description: String
    {
        return "\(self.module).NewUdpFlowRequest[id: \(self.id), uuid: \(self.uuid), willHandle: \(self.willHandle)]"
    }

    public init(_ uuid: UUID, _ willHandle: Bool)
    {
        self.uuid = uuid
        self.willHandle = willHandle

        super.init(module: AppProxyModule.name)
    }
}
