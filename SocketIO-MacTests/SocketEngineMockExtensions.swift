//
//  SocketEngineMockExtensions.swift
//  Socket.IO-Client-Swift
//
//  Created by Erik Little on 8/14/16.
//
//

import Foundation
@testable import SocketIOClientSwift

extension SocketEngine {
    func mockConnect() {
        server.connectEngine(self)
    }
    
    func mockDoFastUpgrade() {
        assert(true)
    }
    
    func mockDoPoll() {
        if websocket || waitingForPoll || !connected || closed || server.testDone { return }
        
        waitingForPoll = true
        
        mockDoLongPoll()
    }
    
    func mockDoLongPoll() {
        server.handlePoll {pollString in
            dispatch_async(self.parseQueue) {
                self.parsePollingMessage(pollString)
            }
            
            self.waitingForPoll = false
            
            if self.fastUpgrade {
                self.mockDoFastUpgrade()
            } else if !self.closed && self.polling {
                self.mockDoPoll()
            }
        }
    }
    
    func mockFlushWaitingForPost() {
        defer { postWait.removeAll() }
        
        if postWait.count == 0 || !connected {
            return
        } else if websocket {
            mockFlushWaitingForPostToWebSocket()
            return
        }
        
        let postString = createPostStringFromPostWait(postWait)
        
        waitingForPost = true
        
        server.receivePollingMessage(postString) {
            dispatch_async(self.emitQueue) {
                if !self.fastUpgrade {
                    self.mockFlushWaitingForPost()
                    self.mockDoPoll()
                }
            }
        }
    }
    
    func mockFlushWaitingForPostToWebSocket() {
        
    }
    
    // TODO: actually mock out ping calculation stuff
    func mockHandleOpen(message: String) {
        client?.engineDidOpen("connect")
    }
    
    func mockSendPollMessage(message: String, withType type: SocketEnginePacketType, withData datas: [NSData]) {
        postWait.append(String(type.rawValue) + message)
        
        for data in datas {
            if case let .Right(bin) = createBinaryDataForSend(data) {
                postWait.append(bin)
            }
        }
        
        if !waitingForPost {
            mockFlushWaitingForPost()
        }
    }
    
    func mockSendWebSocketMessage(str: String, withType type: SocketEnginePacketType, withData datas: [NSData]) {
        let sendString = "\(type.rawValue)\(str)"
        
        server.receiveWebSocketMessage(sendString)
        
        for data in datas {
            if case let .Left(bin) = createBinaryDataForSend(data) {
                server.receiveWebSocketBinary(bin)
            }
        }
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
}
