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
        if let error = maybeError
        {
            return "\(self.module).StartProxyRequest[id: \(self.id), maybeError: \(error)]"
        }
        else
        {
            return "\(self.module).StartProxyRequest[id: \(self.id), maybeError: nil]"
        }
    }

    public init(_ maybeError: Error?)
    {
        self.maybeError = maybeError

        super.init(module: AppProxyModule.name)
    }
}
