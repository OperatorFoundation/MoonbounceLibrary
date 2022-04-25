//
//  MoonbounceConfig.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 1/18/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
//import ReplicantSwift
import Net
import TunnelClient

public class MoonbounceConfig: NSObject
{
    static let filenameExtension = "moonbounce"
    
    let fileManager = FileManager.default
//    public let replicantConfig: ReplicantConfig?
    public var name: String
    public var providerBundleIdentifier: String

    public init(name: String, providerBundleIdentifier: String/*, replicantConfig: ReplicantConfig?*/)
    {
        self.name = name
        self.providerBundleIdentifier = providerBundleIdentifier
//        self.replicantConfig = replicantConfig
    }
}

enum DocumentError: Error
{
    case unrecognizedContent
    case corruptDocument
    case archivingFailure
    
    var localizedDescription: String
    {
        switch self
        {
            
        case .unrecognizedContent:
            return NSLocalizedString("File is an unrecognised format", comment: "")
        case .corruptDocument:
            return NSLocalizedString("File could not be read", comment: "")
        case .archivingFailure:
            return NSLocalizedString("File could not be saved", comment: "")
        }
    }
    
}
