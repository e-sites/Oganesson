//
//  ObjectPool.swift
//  ObjectPool
//
//  Created by Bas van Kuijck on 03/08/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation

/// Every ObjectPool Instance should inherit the `ObjectPoolInstance` protocol. 
public protocol ObjectPoolCompatible: Equatable {
    init()
}

/// An `ObjectPool` class for (de)queueing objects
///
/// ##Init:
///
///      let objectPool = ObjectPool<SomeUIView>(size: 20,policy: .dynamic) { obj in
///          obj.backgroundColor = UIColor.red
///      }
///
/// ##Get an object from the pool:
///
///      do {
///          let object = try objectPool.acquire()
///      } catch let error {
///          print("Error acquiring object: \(error)")
///      }
///
/// ##Done using the object:
///
///      objectPool.release(object)
///
open class ObjectPool<Instance: ObjectPoolCompatible> {

    /// `ObjectPool.Error` types
    public enum Error: Swift.Error {
        /// Error getting an object from the pool, it's drained.
        /// This typically happens for `.static` Policies
        case drained
    }

    /// The acquire policy
    public enum Policy {
        /// If the pool is drained, fill up the pool with +1
        case dynamic

        /// If the pool is drained, throw `Error.drained`
        case `static`
    }

    /// The total available size of the pool
    public var size: Int {
        return _pool.count
    }

    /// How many objects have been acquired, aka pulled out of the pool
    public var acquireCount: Int {
        return _inPool.filter { !$0.value }.count
    }

    /// The `Policy`
    public let policy: Policy

    fileprivate let _queue = DispatchQueue(label: "com.esites.library.oganesson")
    fileprivate var _pool: [Instance] = []
    fileprivate var _inPool: [Int: Bool] = [:]

    fileprivate var factory: ((Instance) -> Void)?
    fileprivate var _onRelease: ((Instance) -> Void)?
    fileprivate var _onAcquire: ((Instance) -> Void)?

    public init(size: Int, policy: Policy = .static, factory: ((Instance) -> Void)? = nil) {
        self.policy = policy
        self.factory = factory

        for _ in 0..<size {
            _addNewObjectToPool()
        }
    }

    @discardableResult
    fileprivate func _addNewObjectToPool() -> Instance {
        let obj = Instance()
        factory?(obj)
        _inPool[_pool.count] = true
        _pool.append(obj)
        return obj
    }

    /// Closure to be called when an object is acquired.
    /// This can be useful if you want to do some general actions on the `Instance` object.
    public func onAcquire(_ closure: ((Instance) -> Void)?) {
        _onAcquire = closure
    }

    /// Closure to be called when an object is released back into the pool.
    /// This can be useful if you want to do some 'cleanup' actions before the object is returned to the pool.
    public func onRelease(_ closure: ((Instance) -> Void)?) {
        _onRelease = closure
    }
}

extension ObjectPool {
    fileprivate func sync(_ closure: () -> Void) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }

    //
    /// Gets an instance from the `ObjectPool`
    ///
    /// - Returns: The `Instance` of the `ObjectPool`
    /// - Throws: See `ObjectPool.Error`
    public func acquire() throws -> Instance {
        var instance: Instance!
        try _queue.sync {
            instance = try self._acquire()
        }

        return instance
    }

    private func _acquire() throws -> Instance {
        func ac(_ obj: Instance) -> Instance {
            if let index = _pool.firstIndex(of: obj) {
                _inPool[index] = false
            }
            sync {
                self._onAcquire?(obj)
            }
            return obj
        }

        guard let instance: Instance = (_pool.filter { obj in
            guard let index = _pool.firstIndex(of: obj) else {
                return false
            }
            return _inPool[index] == true
        }).first else {
            switch policy {
            case .static:
                throw Error.drained

            case .dynamic:
                let tinstance = _addNewObjectToPool()
                return ac(tinstance)
            }
        }
        return ac(instance)
    }
}

extension ObjectPool {
    /// Puts an object back (aka release) into the `ObjectPool`
    ///
    /// - Parameters
    ///    - obj: `Instance`
    /// - Throws: See `ObjectPool.Error`
    public func release(_ obj: Instance) {
        _queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            self.sync {
                guard let index = self._pool.firstIndex(of: obj) else {
                    return
                }

                if self._inPool[index] == true {
                    return
                }
                self._inPool[index] = true
                self._onRelease?(obj)
            }
        }
    }

    /// Drains the entire pool.
    public func drain() {
        _queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            self.sync {
                self._inPool.removeAll()
                self._pool.removeAll()
            }
        }
    }
}
