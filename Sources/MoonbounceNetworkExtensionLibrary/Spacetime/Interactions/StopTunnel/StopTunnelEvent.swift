//
//  StopTunnelEvent.swift
//
//
//  Created by Dr. Brandon Wiley on 3/31/22.
//

import Foundation
import Spacetime
import NetworkExtension

public class StopTunnelEvent: Event
{
    let reason: ProviderStopReason

    public override var description: String
    {
        return "\(self.module).StopTunnelEvent[reason: \(self.reason)]"
    }

    public init(_ reason: NEProviderStopReason)
    {
        self.reason = reason.reason

        super.init(module: NetworkExtensionModule.name)
    }

    public enum CodingKeys: String, CodingKey
    {
        case effectId
        case reason
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let reason = try container.decode(ProviderStopReason.self, forKey: .reason)

        self.reason = reason

        super.init(effectId, module: NetworkExtensionModule.name)
    }
}

public enum ProviderStopReason: Int, Codable
{
    case none = 0
    case userInitiated = 1
    case providerFailed = 2
    case noNetworkAvailable = 3
    case unrecoverableNetworkChange = 4
    case providerDisabled = 5
    case authenticationCanceled = 6
    case configurationFailed = 7
    case idleTimeout = 8
    case configurationDisabled = 9
    case configurationRemoved = 10
    case superceded = 11
    case userLogout = 12
    case userSwitch = 13
    case connectionFailed = 14
    case sleep = 15
    case appUpdate = 16
}

extension ProviderStopReason
{
    public init(_ reason: NEProviderStopReason)
    {
        self = ProviderStopReason(rawValue: reason.rawValue)!
    }

    public var reason: NEProviderStopReason
    {
        return NEProviderStopReason(rawValue: self.rawValue)!
    }
}

extension NEProviderStopReason
{
    public init(_ reason: ProviderStopReason)
    {
        self = NEProviderStopReason(rawValue: reason.rawValue)!
    }

    public var reason: ProviderStopReason
    {
        return ProviderStopReason(rawValue: self.rawValue)!
    }
}
