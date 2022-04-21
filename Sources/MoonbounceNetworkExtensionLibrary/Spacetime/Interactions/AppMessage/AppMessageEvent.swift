//
//  AppMessageEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime

public class AppMessageEvent: Event
{
    let data: Data

    public override var description: String
    {
        return "\(self.module).AppMessageEvent[data: \(self.data)]"
    }

    public init(_ data: Data)
    {
        self.data = data

        super.init(module: NetworkExtensionModule.name)
    }
}
