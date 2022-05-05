//
//  AppMessageRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class AppMessageRequest: Effect
{
    let data: Data?

    public override var description: String
    {
        return "\(self.module).SendProviderMessageRequest[id: \(self.id), data: \(self.data)]"
    }

    public init(_ data: Data?)
    {
        self.data = data

        super.init(module: AppProxyModule.name)
    }
}
