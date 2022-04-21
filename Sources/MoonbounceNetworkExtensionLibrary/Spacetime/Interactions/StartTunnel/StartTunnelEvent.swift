//
//  StartTunnelEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class StartTunnelEvent: Event
{
    let options: [String : NSObject]?

    public override var description: String
    {
        return "\(self.module).StartTunnelEvent[options: \(self.options)]"
    }

    public init(options: [String : NSObject]? = nil)
    {
        self.options = options

        super.init(module: NetworkExtensionModule.name)
    }
}
