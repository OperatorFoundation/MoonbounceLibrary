import XCTest
@testable import MoonbounceLibrary
import TunnelClientMock
import TunnelClient
import TunnelClientMacOS
import Chord
import NetworkExtension

final class MoonbounceLibraryTests: XCTestCase {
    func testMockRead() throws {
        let pongReceived: XCTestExpectation = XCTestExpectation(description: "pong received")
        
        // load the writes with data beforehand
        let packetRead = BlockingQueue<PacketTunnelFlowPacket>()
        let packetWrite = BlockingQueue<PacketTunnelFlowPacket>()
        let messageRead = BlockingQueue<Data>()
        let messageWrite = BlockingQueue<Data>()
        
        let newPacket = "45000054edfa00004001baf10A000003080808080800335dde64021860f5bcab0009db7808090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323334353637"
        let pingPacket = Data(hex: newPacket)
        let nsNumber = NSNumber(value: 4)
        let completionHandler:([Data], [NSNumber]) -> Void = {completionBuffer, completionNSNumber  in }
        
        
        let mptp = PacketTunnelProvider(packetReadQueue: packetRead, packetWriteQueue: packetWrite, messageReadQueue: messageRead, messageWriteQueue: messageWrite)
        // call startTunnel()
        mptp.startTunnel
        {
            maybeError in
            print("ready to go!")
            
            // give the queue a packet to read
            packetRead.enqueue(element: (pingPacket, nsNumber))
            
            // take packet out
            let (pongPacket, _) = packetWrite.dequeue()
            pongReceived.fulfill()
        }
        
        wait(for: [pongReceived], timeout: 15) // 15 seconds
    }
}
