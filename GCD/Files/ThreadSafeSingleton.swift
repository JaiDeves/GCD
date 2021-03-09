//
//  ThreadSafeSingleton.swift
//  GCD
//
//  Created by apple on 09/03/21.
//
//https://medium.com/swiftcraft/swift-solutions-singleton-27e932879dfb
//https://blog.autsoft.hu/thread-safe-singletons-swift-gcd/

import Foundation

class Printer {
  // 1
  private let concurrentQueue = DispatchQueue(label: "ConcurrentQueue", attributes: .concurrent, target: nil)
  private var queue = [String: String]()
  static let sharedInstance = Printer()
 
  private init() { }
  
  func set(value: String, for key: String) {
    // 2
    concurrentQueue.async(flags: .barrier) {
      self.queue[key] = value
    }
  }
  
  func value(for key: String) -> String? {
    var result: String?
    // 3
    concurrentQueue.sync {
      result = queue[key]
    }
    return result
  }
}
