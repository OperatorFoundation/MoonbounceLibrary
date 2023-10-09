import XCTest
@testable import MoonbounceLibrary
@testable import MoonbounceNetworkExtensionLibrary

import Logging
import os.log

import Chord
import Gardener
import KeychainCli
import MoonbounceShared
import ShadowSwift
import Transmission
import TransmissionAsync
import NetworkExtension
//import ReplicantSwift

final class MoonbounceLibraryTests: XCTestCase
{
    func testTCPConnect() async throws {
        let expectation = XCTestExpectation(description: "connected")
        Task {
            let logger = Logger(label: "MoonbounceTest")
            let _ = try await AsyncTcpSocketConnection("137.184.52.124", 7, logger)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testTCP() async throws {
        let expectation = XCTestExpectation(description: "connected")
        Task {
            let testData = Data(repeating: "a".data[0], count: 10)
            let logger = Logger(label: "MoonbounceTest")
            let connection = try await AsyncTcpSocketConnection("137.184.52.124", 7, logger)
            try await connection.write(testData)
            let receivedData = try await connection.readSize(testData.count)
            XCTAssertEqual(testData, receivedData)
        }
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testTCPBigData() async throws {
        let expectation = XCTestExpectation(description: "connected")
        Task {
            let testData = Data(repeating: "a".data[0], count: 2000)
            let logger = Logger(label: "MoonbounceTest")
            let connection = try await AsyncTcpSocketConnection("137.184.52.124", 7, logger)
            expectation.fulfill()
            try await connection.write(testData)
            let receivedData = try await connection.readSize(testData.count)
            XCTAssertEqual(testData, receivedData)
        }
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testUDP() async throws {
        let expectation = XCTestExpectation(description: "connected")
        Task {
            let testData = Data(repeating: "a".data[0], count: 10)
            let host: Network.NWEndpoint.Host = "137.184.52.124"
            let port: Network.NWEndpoint.Port = 7
            let connection = NWConnection(host: host, port: port, using: .udp)
            expectation.fulfill()
            connection.stateUpdateHandler = {
                state in
                
                switch state {
                case .ready:
                    connection.send(content: testData, completion: NWConnection.SendCompletion.contentProcessed({
                        error in
                        
                        guard error == nil else {
                            XCTFail()
                            return
                        }
                        
                        connection.receiveMessage(completion: {
                            data, context, isComplete, error in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            
                            XCTAssertEqual(testData, data)
                        })
                    }))
                default:
                    print(state)
                }
            }
        }
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testLoadPreferences()
    {
        let logger = Logger()
        let moonbounce = MoonbounceLibrary(logger: logger)
        do
        {
            guard let shadowConfig = ShadowConfig.ShadowClientConfig(path: File.homeDirectory().appendingPathComponent("ShadowClientConfig.json").path) else
            {
                XCTFail()
                return
            }
            
            try moonbounce.configure(shadowConfig, providerBundleIdentifier: "NetworkExtension", tunnelName: "default")
        }
        catch
        {
            print("error loading configuration: \(error)")
            XCTFail()
        }
        print("configuration complete")
    }
    
    func testDeserializeConfig() throws
    {
        let _ = ShadowConfig.createNewConfigFiles(inDirectory: File.homeDirectory(), serverAddress: "127.0.0.1", cipher: .DARKSTAR)
        
        guard let _ = ShadowConfig.ShadowClientConfig(path: File.homeDirectory().appendingPathComponent("ShadowClientConfig.json").path) else
        {
            XCTFail()
            return
        }
    }
}
