//
//  StartProxyEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StartProxyEvent: Event
{
    let options: [String : Any]?

    public override var description: String
    {
        return "\(self.module).StartProxyEvent[options: \(self.options)]"
    }

    public init(options: [String : NSObject]? = nil)
    {
        self.options = options

        super.init(module: AppProxyModule.name)
    }
}
