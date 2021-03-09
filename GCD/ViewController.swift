//
//  ViewController.swift
//  GCD
//
//  Created by apple on 09/03/21.
//

import UIKit

class ViewController: UIViewController {
    let gcd = GCD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleGCD()
    }
    
    func handleGCD(){
//        gcd.runloop()
        testThreadSafeArray()
    }
    
    func testThreadSafeArray(){
        // Thread-unsafe array
        do {
            var array = [Int]()
            var iterations = 1000
            let start = Date().timeIntervalSince1970

            DispatchQueue.concurrentPerform(iterations: iterations) { index in
                let last = array.last ?? 0
                array.append(last + 1)

                DispatchQueue.global().sync {
                    iterations -= 1

                    // Final loop
                    guard iterations <= 0 else { return }
                    let message = String(format: "Unsafe loop took %.3f seconds, count: %d.",
                        Date().timeIntervalSince1970 - start,
                        array.count)
                    print(message)
                }
            }
        }
         
        // Thread-safe array
        do {
            var array = SynchronizedArray<Int>()
            var iterations = 1000
            let start = Date().timeIntervalSince1970
         
            DispatchQueue.concurrentPerform(iterations: iterations) { index in
                let last = array.last ?? 0
                array.append(last + 1)
         
                DispatchQueue.global().sync {
                    iterations -= 1
                 
                    // Final loop
                    guard iterations <= 0 else { return }
                    let message = String(format: "Safe loop took %.3f seconds, count: %d.",
                        Date().timeIntervalSince1970 - start,
                        array.count)
                    print(message)
                }
            }
        }
         
    }

}

