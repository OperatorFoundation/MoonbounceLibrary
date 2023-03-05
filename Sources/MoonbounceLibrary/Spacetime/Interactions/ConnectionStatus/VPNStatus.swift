//
//  NEVPNStatus+Codable.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/3/23.
//

import Foundation
import NetworkExtension

public enum VPNStatus: Int, Codable
{
    case invalid = 0
    case disconnected = 1
    case connecting = 2
    case connected = 3
    case reasserting = 4
    case disconnecting = 5
}

extension VPNStatus
{
    public var neVPNStatus: NEVPNStatus
    {
        return NEVPNStatus(rawValue: self.rawValue)!
    }
}

extension NEVPNStatus
{
    public var vpnStatus: VPNStatus
    {
        return VPNStatus(rawValue: self.rawValue)!
    }
}
