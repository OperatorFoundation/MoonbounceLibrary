//
//  StartTunnelRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StartTunnelRequest: Effect
{
    let maybeError: String?

    public override var description: String
    {
        if let error = maybeError
        {
            return "\(self.module).StartTunnelRequest[id: \(self.id), maybeError: \(error)]"
        }
        else
        {
            return "\(self.module).StartTunnelRequest[id: \(self.id), maybeError: nil]"
        }
    }

    public init(_ maybeError: Error?)
    {
        if let error = maybeError
        {
            self.maybeError = error.localizedDescription
        }
        else
        {
            self.maybeError = nil
        }

        super.init(module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case id
        case maybeError
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let maybeError = try container.decode(String?.self, forKey: .maybeError)

        self.maybeError = maybeError

        super.init(id: id, module: NetworkExtensionModule.name)
    }
}
