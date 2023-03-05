//
//  ConnectionStatusResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class ConnectionStatusResponse: Event
{
    let status: VPNStatus

    public override var description: String
    {
        return "\(self.module).ConnectionStatusResponse[effectID: \(String(describing: self.effectId)), status: \(self.status)]"
    }

    public init(_ effectId: UUID, _ status: VPNStatus)
    {
        self.status = status
        
        super.init(effectId, module: VPNModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
        case status
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let status = try container.decode(VPNStatus.self, forKey: .status)

        self.status = status

        super.init(effectId, module: VPNModule.name)
    }
}
