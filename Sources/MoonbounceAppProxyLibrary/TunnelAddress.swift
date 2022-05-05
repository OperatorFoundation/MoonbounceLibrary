//
//  TunnelAddress.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/3/22.
//

import Foundation
import Net

public enum TunnelAddress
{
    case ipV4(IPv4Address)
    case ipV6(IPv6Address)
    case dualStack(IPv4Address, IPv6Address)
}
