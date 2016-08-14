//
//  SocketEngineTest.swift
//  Socket.IO-Client-Swift
//
//  Created by Erik Little on 8/14/16.
//
//  Tests server interactions: upgrading transport, probing, etc...

import XCTest
@testable import SocketIOClientSwift

let server = SocketMockServer()

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
        server.sendWaiting.removeAll()
        server.engine = engine
        server.testDone = false
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
    
    func testSendPolling() {
        engine.setTestable()
        engine.setWebSocket(false)
        
        server.waitingMessages = ["hello world"]
        server.expectation = expectationWithDescription("Engine should send polling")
        
        engine.mockWrite("hello world", withType: .Message, withData: [])
        
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testDoLongPoll() {
        engine.setTestable()
        engine.setWebSocket(false)
        
        server.sendWaiting = ["4hello world"]
        server.expectation = expectationWithDescription("Engine should get long poll message")
        
        engine.mockDoPoll()
        
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testPollingAlsoGetsWaitingData() {
        engine.setTestable()
        engine.setWebSocket(false)
        
        server.sendWaiting = ["4hello world", "4cat"]
        server.waitingMessages = ["hello worlddddd"]
        server.expectation = expectationWithDescription("Engine should get long poll message")
        
        engine.mockWrite("hello worlddddd", withType: .Message, withData: [])
        
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
