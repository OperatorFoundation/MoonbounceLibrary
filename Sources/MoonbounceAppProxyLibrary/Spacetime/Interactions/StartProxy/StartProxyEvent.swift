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
        if let options = options
        {
            return "\(self.module).StartProxyEvent[options: \(options)]"
        }
        else
        {
            return "\(self.module).StartProxyEvent[options: nil]"
        }
    }

    public init(options: [String : NSObject]? = nil)
    {
        self.options = options

        super.init(module: AppProxyModule.name)
    }
}
