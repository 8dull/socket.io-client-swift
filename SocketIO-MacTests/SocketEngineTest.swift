//
//  SocketEngineTest.swift
//  Socket.IO-Client-Swift
//
//  Created by Erik Little on 8/14/16.
//
//  Tests server interactions: upgrading transport, probing, etc...

import XCTest
@testable import SocketIOClientSwift

private let server = SocketMockServer()

extension SocketEngine {
    func mockConnect() {
        server.connectEngine(self)
    }
    
    // TODO: actually mock out ping calculation stuff
    func mockHandleOpen(message: String) {
        client?.engineDidOpen("connect")
    }
    
    func mockWrite(msg: String, withType type: SocketEnginePacketType, withData data: [NSData]) {
        dispatch_async(emitQueue) {
            guard self.connected else { return }
            
            if self.websocket {
                self.mockSendWebSocketMessage(msg, withType: type, withData: data)
            } else if !self.probing {
                self.mockSendPollMessage(msg, withType: type, withData: data)
            } else {
                self.addProbe((msg, type, data))
            }
        }
    }
    
    func mockSendPollMessage(message: String, withType type: SocketEnginePacketType, withData datas: [NSData]) {
        
    }
    
    func mockSendWebSocketMessage(str: String, withType type: SocketEnginePacketType, withData datas: [NSData]) {
        let sendString = "\(type.rawValue)\(str)"
        
        server.receiveWebSocketMessage(sendString)
        
        for data in datas {
            if case let .Left(bin) = createBinaryDataForSend(data) {
                print(bin)
                server.receiveWebSocketBinary(bin)
            }
        }
    }
}

class SocketEngineTest : XCTestCase, SocketEngineClient {
    let data = "1".dataUsingEncoding(NSUTF8StringEncoding)!
    let data2 = "2".dataUsingEncoding(NSUTF8StringEncoding)!
    
    var engine: SocketEngine!
    var expectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        
        engine = SocketEngine(client: self, url: NSURL(), config: [])
        server.waitingMessages.removeAll()
        server.waitingBinary.removeAll()
    }
    
    func testEngineConnect() {
        expectation = expectationWithDescription("Engine should connect")
        engine.mockConnect()
        
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testSendWebSocket() {
        engine.setTestable()
        engine.setWebSocket(true)
        
        server.waitingMessages = ["hello world"]
        server.expectation = expectationWithDescription("Engine should send websocket")
        
        engine.mockWrite("hello world", withType: .Message, withData: [])
        
        waitForExpectationsWithTimeout(3, handler: nil)
        
    }
    
    func testSendWebSocketWithBinary() {
        engine.setTestable()
        engine.setWebSocket(true)
        
        server.waitingMessages = ["hello world"]
        server.waitingBinary = [data, data2]
        server.expectation = expectationWithDescription("Engine should send websocket with binary")
        
        engine.mockWrite("hello world", withType: .Message, withData: [data, data2])
        
        waitForExpectationsWithTimeout(3, handler: nil)
        
    }
}

extension SocketEngineTest {
    func engineDidError(reason: String) {
        
    }
    
    func engineDidClose(reason: String) {
        
    }
    
    func engineDidOpen(reason: String) {
        expectation?.fulfill()
    }
    
    func parseEngineMessage(msg: String) {
        
    }
    
    func parseEngineBinaryData(data: NSData) {
        
    }
}
