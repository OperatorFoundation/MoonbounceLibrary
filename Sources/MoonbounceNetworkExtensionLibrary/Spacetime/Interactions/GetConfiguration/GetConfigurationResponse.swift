//
//  GetConfigurationResponse.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import NetworkExtension
import Spacetime

public class GetConfigurationResponse: Event
{
    let configuration: NETunnelProviderProtocol

    public override var description: String
    {
        return "\(self.module).GetConfigurationResponse[effectID: \(String(describing: self.effectId)), configuration: \(self.configuration)]"
    }

    public init(_ effectId: UUID, _ configuration: NETunnelProviderProtocol)
    {
        self.configuration = configuration

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}
