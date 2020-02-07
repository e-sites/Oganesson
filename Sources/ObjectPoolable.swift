//
//  ObjectPoolable.swift
//  Oganesson
//
//  Created by Bas van Kuijck on 07/02/2020.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation

@propertyWrapper
public class ObjectPoolable<Object: ObjectPoolCompatible> {

    public let wrappedValue: Object

    let objectPool: ObjectPool<Object>

    public init(objectPool: ObjectPool<Object>) {
        self.objectPool = objectPool
        
        do {
            wrappedValue = try objectPool.acquire()
        } catch let error {
            fatalError(String(describing: error))
        }
    }

    deinit {
        objectPool.release(wrappedValue)
    }
}

