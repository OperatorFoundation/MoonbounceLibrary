//
//  ProxyError.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/3/22.
//

import Foundation

public enum ProxyError: Error
{
    case badConfiguration
    case badConnection
    case cancelled
    case disconnected
    case internalError
}
