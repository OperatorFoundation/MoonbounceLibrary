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
        if let someOptions = options
        {
            return "\(self.module).StartTunnelEvent[options: \(someOptions)]"
        }
        else
        {
            return "\(self.module).StartTunnelEvent[options: nil]"
        }
    }

    public init(options: [String : NSObject]? = nil)
    {
        self.options = options

        super.init(module: NetworkExtensionModule.name)
    }
}
