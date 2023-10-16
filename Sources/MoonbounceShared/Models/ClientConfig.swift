//  Created by Joshua Clark on 11/21/22.
//  Copyright © 2022 operatorfoundation.org. All rights reserved.
//

import Foundation

import Keychain

public struct ClientConfig: Codable
{
    public let name: String
    public let host: String
    public let port: Int
    public let serverPublicKey: PublicKey

    public init(name: String, host: String, port: Int, serverPublicKey: PublicKey)
    {
        self.name = name
        self.host = host
        self.port = port
        self.serverPublicKey = serverPublicKey
    }
}
