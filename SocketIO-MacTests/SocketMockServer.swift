//
//  SocketMockServer.swift
//  Socket.IO-Client-Swift
//
//  Created by Erik Little on 8/14/16.
//
//

import XCTest
@testable import SocketIOClientSwift

class SocketMockServer {
    let socketQueue = dispatch_queue_create("server", DISPATCH_QUEUE_SERIAL)
    
    var engine: SocketEngine!
    var expectation: XCTestExpectation?
    var waitingBinary = [NSData]()
    var waitingMessages = [String]()
    
    func fulfillExpectation() {
        guard waitingMessages.count == 0 && waitingBinary.count == 0 else { return }
        
        expectation?.fulfill()
    }
    
    func connectEngine(engine: SocketEngine) {
        self.engine = engine
        
        engine.mockHandleOpen("0")
    }
    
    func handleBinary(data: NSData) {
        removeItem(data, fromWaiting: &waitingBinary)
        
        fulfillExpectation()
    }
    
    func handleMessage(message: String) {
        let reader = SocketStringReader(message: message)
        
        if message.hasPrefix("b4") {
            // binary in base64 string
            let noPrefix = message[message.startIndex.advancedBy(2)..<message.endIndex]
            
            if let data = NSData(base64EncodedString: noPrefix, options: .IgnoreUnknownCharacters) {
               handleBinary(data)
            }
            
            return
        }

        guard let type = SocketEnginePacketType(rawValue: Int(reader.currentCharacter) ?? -1) else {
            return
        }
        
        let noType = message[message.startIndex.successor()..<message.endIndex]
        
        switch type {
        case .Message:
            removeItem(noType, fromWaiting: &waitingMessages)
        default:
            break
        }
        
        fulfillExpectation()
    }
    
    func parsePollingMessage(message: String) {
        guard message.characters.count != 1 else { return }
        
        var reader = SocketStringReader(message: message)
        
        while reader.hasNext {
            if let n = Int(reader.readUntilStringOccurence(":")) {
                let message = reader.read(n)
                
                handleMessage(message)
            } else {
                handleMessage(message)
                
                break
            }
        }
    }
    
    func receiveWebSocketBinary(data: NSData) {
        dispatch_async(socketQueue) {
            self.handleBinary(data.subdataWithRange(NSMakeRange(1, data.length - 1)))
        }
    }
    
    func receivePollingMessage(message: String) {
        dispatch_async(socketQueue) {
            self.parsePollingMessage(message)
        }
    }
    
    func receiveWebSocketMessage(message: String) {
        dispatch_async(socketQueue) {
            self.handleMessage(message)
        }
    }
    
    func removeItem<T: Equatable>(item: T, inout fromWaiting waiting: [T]) {
        var i = 0
        var count = waiting.count
        
        repeat {
            if item == waiting[i] {
                waiting.removeAtIndex(i)
                count -= 1
            }
            
            i += 1
        } while i < count
    }
}
