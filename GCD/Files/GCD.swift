//
//  GCD.swift
//  GCD
//https://theswiftdev.com/ultimate-grand-central-dispatch-tutorial-in-swift/
//https://medium.com/@roykronenfeld/semaphores-in-swift-e296ea80f860


import Foundation


class GCD{
    
    //Deleay Exececution
    func delayOnMain(time:TimeInterval,task:@escaping ()->Void){
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            task()
        }
    }
    
    func concurrentLoop(iterations:Int){
        DispatchQueue.concurrentPerform(iterations: iterations) { (i) in
            print(i)
        }
    }
    ///With work item you can cancel a running task. Also work items can notify a queue when their task is completed.
    func workItem(){
        var workItem: DispatchWorkItem?
        workItem = DispatchWorkItem {
            for i in 1..<6 {
                guard let item = workItem, !item.isCancelled else {
                    print("cancelled")
                    break
                }
                sleep(1)
                print(String(i))
            }
        }

        workItem?.notify(queue: .main) {
            print("done")
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            workItem?.cancel()
        }
        DispatchQueue.main.async(execute: workItem!)
        
        // you can use perform to run on the current queue instead of queue.async(execute:)
        //workItem?.perform()

    }
    
    //Multiple (network) concurrent calls with notifier
    func dispatchGroup(){

        let group = DispatchGroup()

        group.enter()
        load(delay: 1) {
            print("1")
            group.leave()
        }

        group.enter()
        load(delay: 2) {
            print("2")
            group.leave()
        }

        group.enter()
        load(delay: 3) {
            print("3")
            group.leave()
        }

        group.notify(queue: .main) {
            print("done")
        }
    }
    
    func load(delay: UInt32, completion: () -> Void) {
        sleep(delay)
        completion()
    }

    ///    The dispatch group also allows us to track the completion of different work items, even if they run on different queues.
    func dispatchGroupWorkItem(){
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "com.theswiftdev.queues.serial")
        
        let workItem = DispatchWorkItem {
            print("start")
            sleep(1)
            print("end")
        }

        serialQueue.async(group: group) {
            print("group start")
            sleep(2)
            print("group end")
        }
        DispatchQueue.global().async(group: group, execute: workItem)

        // you can block your current queue and wait until the group is ready
        // a better way is to use a notification block instead of blocking
        //group.wait(timeout: .now() + .seconds(3))
        //print("done")

        group.notify(queue: .main) {
            print("done")
        }
    }
    
    func dispatchGroupWait(){
        let queue = DispatchQueue.global()
        let group = DispatchGroup()
        let n = 9
        for i in 0..<n {
            queue.async(group: group) {
                print("\(i): Running async task...")
                sleep(3)
                print("\(i): Async task completed")
            }
        }
        group.wait()
        print("done")
    }

    ///    A semaphore is simply a variable used to handle resource sharing in a concurrent system.
///    Semaphores gives us the ability to control access to a shared resource by multiple threads
    func sempaphore(){
    }
    

    //    To make an async task to synchronous, use semaphore
    func makeAnAsyncToSync(){
        enum DispatchError: Error {
            case timeout
        }

        func asyncMethod(completion: (String) -> Void) {
            sleep(2)
            completion("done")
        }

        func syncMethod() throws -> String {

            let semaphore = DispatchSemaphore(value: 0)
            let queue = DispatchQueue.global()

            var response: String?
            queue.async {
                asyncMethod { r in
                    response = r
                    //            You increment a semaphore count by calling the signal()
                    semaphore.signal()
                }
            }
//            decrement a semaphore count by calling wait() or one of its variants that specifies a timeout
            _ = semaphore.wait(timeout: .now() + 5)
            guard let result = response else {
                throw DispatchError.timeout
            }
            return result
        }

        if let response = try? syncMethod(){
            print(response )
        }
    }
    
    
    func lockedNumberSemaphore(){
        
        let items = LockedNumbers()
        items.append(1)
        items.append(2)
        items.append(5)
        items.append(3)
        items.removeLast()
        items.removeLast()
        items.append(3)
        print(items.elements)
    }
    
/// Batch execution using semaphore
    func batchSemaphore(){
        print("start")
        let sem = DispatchSemaphore(value: 5)
        for i in 0..<10 {
            DispatchQueue.global().async {
                sem.wait()
                sleep(2)
                print(i)
                sem.signal()
            }
        }
        print("end")
    }
//    The purpose of a run loop is to keep your thread busy when there is work to do and put your thread to sleep when there is none
    func runloop(){
        let t = Thread {
            print(Thread.current.name ?? "")
             let timer = Timer(timeInterval: 1, repeats: true) { t in
                 print("tick")
             }
            RunLoop.current.add(timer, forMode: RunLoop.Mode.default)

            RunLoop.current.run()
            RunLoop.current.run(mode: RunLoop.Mode.common, before: Date.distantPast)
        }
        t.name = "my-thread"
        t.start()

        //RunLoop.current.run()
    }
}


extension DispatchQueue {
    static var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))!
    }
}


class LockedNumbers {

    let semaphore = DispatchSemaphore(value: 1)
    var elements: [Int] = []

    func append(_ num: Int) {
        _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
        print("appended: \(num)")
        self.elements.append(num)
        self.semaphore.signal()
    }

    func removeLast() {
        self.semaphore.wait(timeout: DispatchTime.distantFuture)
        defer {
            self.semaphore.signal()
        }
        guard !self.elements.isEmpty else {
            return
        }
        let num = self.elements.removeLast()
        print("removed: \(num)")
    }
}
