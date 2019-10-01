![Oganesson](Assets/Logo.png)

Oganesson is part of the **[E-sites iOS Suite](https://github.com/e-sites/iOS-Suite)**.

---

A small swift helper class for using an ObjectPool

[![forthebadge](http://forthebadge.com/images/badges/made-with-swift.svg)](http://forthebadge.com) [![forthebadge](http://forthebadge.com/images/badges/built-with-swag.svg)](http://forthebadge.com)

[![Platform](https://img.shields.io/cocoapods/p/Oganesson.svg?style=flat)](http://cocoadocs.org/docsets/Oganesson)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Oganesson.svg)](https://cocoapods.org/pods/Oganesson)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Travis-ci](https://travis-ci.com/e-sites/Oganesson.svg?branch=master)](https://travis-ci.com/e-sites/Oganesson)

Compatible with:

- Swift 5
- Xcode 11


## Installation

### CocoaPods
```ruby
pod 'Oganesson'
```

### SwiftPM

```swift
 .package(url: "https://github.com/e-sites/Oganesson", .branch("master")
```

## Usage
### Init
```swift
class SomeView: UIView, ObjectPoolCompatible {
    required convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100)
    }
}

var objectPool: ObjectPool<SomeView>!

override func viewDidLoad() {
   super.viewDidLoad()
    
   objectPool = ObjectPool<SomeView>(size: 20, policy: .dynamic) { obj in
       obj.backgroundColor = UIColor.red
   }
   
   objectPool.onAcquire { [view] obj in 
       DispatchQueue.main.async {
          view.addSubview(obj)
       }
   }
   
   objectPool.onRelease { obj in 
       DispatchQueue.main.async {
           // It's safe to remove the object from its superview,
           // since `ObjectPool` will keep its (memory) retained.
           obj.removeFromSuperview()
      }
   }
}
```

### Get an object from the pool:
```swift
do {
    let object = try objectPool.acquire()
    object.backgroundColor = UIColor.orange
} catch let error {
    print("Error acquiring object: \(error)")
}
```

### Done using the object:
```swift
objectPool.release(object)
```

### Policies

- `dynamic`: If the pool is drained, fill up the pool with +1
- `static `: The pool size is fixed. If the pool is drained, throw `Error.drained`