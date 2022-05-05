//
//  StartProxyRequest.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StartProxyRequest: Effect
{
    let maybeError: Error?

    public override var description: String
    {
        return "\(self.module).StartProxyRequest[id: \(self.id), maybeError: \(self.maybeError)]"
    }

    public init(_ maybeError: Error?)
    {
        self.maybeError = maybeError

        super.init(module: AppProxyModule.name)
    }
}
