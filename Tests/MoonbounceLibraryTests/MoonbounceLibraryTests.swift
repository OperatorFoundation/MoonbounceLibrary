import XCTest
@testable import MoonbounceLibrary
@testable import MoonbounceNetworkExtensionLibrary
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

        let newPacket = "45000054edfa00004001baf10A000003080808080800335dde64021860f5bcab0009db7808090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323334353637"
        guard let pingPacket = Data(hex: newPacket) else
        {
            XCTFail()
            return
        }
        
        let nsNumber = NSNumber(value: 4)
        let completionHandler:([Data], [NSNumber]) -> Void = {completionBuffer, completionNSNumber  in }
        
        let mptp = MoonbouncePacketTunnelProvider()

        // call startTunnel()
        mptp.startTunnel
        {
            maybeError in
            print("ready to go!")
            
            if let flow = mptp.packets as? MockPacketTunnelFlow
            {
                // give the queue a packet to read
                flow.readQueue.enqueue(element: (pingPacket, nsNumber))

                // take packet out
                let (pongPacket, _) = flow.writeQueue.dequeue()
                pongReceived.fulfill()
            }
        }
        
        wait(for: [pongReceived], timeout: 15) // 15 seconds
    }
}
