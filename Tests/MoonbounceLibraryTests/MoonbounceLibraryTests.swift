//import XCTest
//@testable import MoonbounceLibrary
//@testable import MoonbounceNetworkExtensionLibrary
//
//import os.log
//
//import Chord
//import Gardener
//import KeychainCli
//import MoonbounceShared
//import ShadowSwift
//import Transmission
//import NetworkExtension
////import ReplicantSwift
//
//final class MoonbounceLibraryTests: XCTestCase
//{
////    func testMockRead() throws
////    {
////        let pongReceived: XCTestExpectation = XCTestExpectation(description: "pong received")
////
////        let newPacket = "45000054edfa00004001baf10A000001080808080800335dde64021860f5bcab0009db7808090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323334353637"
////
////        guard let pingPacket = Data(hex: newPacket) else
////        {
////            XCTFail()
////            return
////        }
////
////        let nsNumber = NSNumber(value: 4)
////        let
////        moonbouncePacketTunnelProvider = MoonbouncePacketTunnelProvider()
////        moonbouncePacketTunnelProvider.configuration.serverAddress = ""
////        guard var tunnelProviderProtocol = moonbouncePacketTunnelProvider.configuration as? TunnelProviderProtocol else
////        {
////            print("failed to cast moonbouncePacketTunnelProvider to a TunnelProviderProtocol")
////            XCTFail()
////            return
////        }
////
////        let configDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Configs", isDirectory: true)
////        let configPath = configDirectory.appendingPathComponent("FixedByteTypeReplicantClient.json", isDirectory: false).path
////
//////        guard let replicantConfig = ReplicantConfig(withConfigAtPath: configPath) else
//////        {
//////            print("failed to parse replicantConfig at path: \(configPath)")
//////            XCTFail()
//////            return
//////        }
//////
//////        let replicantConfigData = replicantConfig.createJSON()
////
////        var map = [String:Any]()
//////        map[Keys.replicantConfigKey.rawValue] = replicantConfigData
//////        map[Keys.replicantConfigKey.rawValue] = "{\"serverIP\" : \"10.0.0.1\",\"port\" : 1234}".data
////        map[Keys.tunnelNameKey.rawValue] = "Moonbounce"
////
////        tunnelProviderProtocol.providerConfiguration = map
////
////        // call startTunnel()
////        moonbouncePacketTunnelProvider.startTunnel
////        {
////            maybeError in
////
////            print("ready to go!")
////
////            if let flow = moonbouncePacketTunnelProvider.packets as? MockPacketTunnelFlow
////            {
////                // give the queue a packet to read
////                flow.readQueue.enqueue(element: (pingPacket, nsNumber))
////
////                // take packet out
////                let _ = flow.writeQueue.dequeue()
////                pongReceived.fulfill()
////            }
////        }
////
////        wait(for: [pongReceived], timeout: 15) // 15 seconds
////    }
//    
//    func testReplicantSwiftServer()
//    {
//        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "host", port: 1234) else
//
//        {
//            XCTFail()
//            return
//        }
//        
//        let flowerConnection = FlowerConnection(connection: transmissionConnection, log: nil)
//        let data = "a".data
//        let message = Message.IPDataV4(data)
//
//        print("wrote")
//
//        flowerConnection.writeMessage(message: message)
//
//        guard let ipAssign = flowerConnection.readMessage() else
//        {
//          XCTFail()
//          return
//        }
//
//        print(ipAssign)
//        print("read")
//    }
//    
//    func testLoadPreferences()
//    {
//        let logger = Logger()
//        let moonbounce = MoonbounceLibrary(logger: logger)
//        do
//        {
//            guard let shadowConfig = ShadowConfig.ShadowClientConfig(path: File.homeDirectory().appendingPathComponent("ShadowClientConfig.json").path) else
//            {
//                XCTFail()
//                return
//            }
//            
//            try moonbounce.configure(shadowConfig, providerBundleIdentifier: "NetworkExtension", tunnelName: "default")
//        }
//        catch
//        {
//            print("error loading configuration: \(error)")
//            XCTFail()
//        }
//        print("configuration complete")
//    }
//    
//    func testDeserializeConfig()
//    {
//        try? ShadowConfig.createNewConfigFiles(inDirectory: File.homeDirectory(), serverAddress: "127.0.0.1", cipher: .DARKSTAR)
//        
//        guard let shadowConfig = ShadowConfig.ShadowClientConfig(path: File.homeDirectory().appendingPathComponent("ShadowClientConfig.json").path) else
//        {
//            XCTFail()
//            return
//        }
//    }
//}
