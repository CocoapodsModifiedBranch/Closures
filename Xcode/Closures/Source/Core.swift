/**
 The MIT License (MIT)
 Copyright (c) 2017 Vincent Hesener
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
 is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or
 substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

protocol DelegateProtocol: AnyObject {}

@available(iOS 9.0, *)
public protocol DelegatorProtocol: AnyObject {
    /**
     Clears any delegates/datasources that were assigned by the `Closures`
     framework for this object. This cleans up memory as well as sets the
     delegate/datasource properties to nil.
     */
    @available(iOS 9.0, *)
    func clearClosureDelegates()
}

@available(iOS 9.0, *)
class DelegateWrapper<Delegator: DelegatorProtocol, Delegate: DelegateProtocol>: NSObject {
    weak var delegator: Delegator?
    let delegate: Delegate
    
    init(delegator: Delegator, delegate: Delegate) {
        self.delegate = delegate
        self.delegator = delegator
    }
    
    var tupac: Bool { return delegator == nil }
    
    public static func wrapper(delegator: Delegator,
                               delegate: @autoclosure () -> Delegate,
                               delegates: inout Set<DelegateWrapper<Delegator, Delegate>>,
                               bind: (_ delegator: Delegator, _ delegate: Delegate) -> Void) -> DelegateWrapper<Delegator, Delegate>
    {
        var deadRappers = [DelegateWrapper<Delegator, Delegate>]()
        defer {
            delegates.subtract(deadRappers)
        }
        
        if let wrapper = delegates.first(where: {
            // lazy, inaccurate cleanup.
            if $0.tupac {
                deadRappers.append($0)
            }
            return $0.delegator === delegator
        }) {
            return wrapper
        }
        let delegate = delegate()
        let wrapper: DelegateWrapper<Delegator, Delegate> = DelegateWrapper(delegator: delegator, delegate: delegate)
        bind(delegator, delegate)
        delegates.insert(wrapper)
        
        return wrapper
    }
    
    public static func remove(delegator: Delegator, from delegates: inout Set<DelegateWrapper<Delegator, Delegate>>) {
        if let wrapper = delegates.first(where: { $0.delegator === delegator }) {
            delegates.remove(wrapper)
        }
    }
    
    @available(iOS 9.0, *)
    public static func update(_ delegator: Delegator,
                              delegate: @autoclosure () -> Delegate,
                              delegates: inout Set<DelegateWrapper<Delegator, Delegate>>,
                              bind: (_ delegator: Delegator, _ delegate: Delegate) -> Void,
                              with updateHandler: (_ wrapper: DelegateWrapper<Delegator, Delegate>) -> Void)
    {
        let wrapper = self.wrapper(delegator: delegator, delegate: delegate(), delegates: &delegates, bind: bind)
        updateHandler(wrapper)
        bind(delegator, wrapper.delegate)
    }
}

private class BundleHook {}
extension Bundle {
    static let closures = Bundle(for: BundleHook.self)
}

extension String {
    static let namespace = Bundle.closures.bundleIdentifier ?? ""
}

extension NotificationCenter {
    static func selfObserve<T: NSObject>(name: Notification.Name,
                                         target: T,
                                         closure: @escaping (_ target: T, _ userInfo: [AnyHashable: Any]?) -> Void) where T: AnyObject
    {
        target.closureWrapper.owner = target
        target.closureWrapper.observe(name: name) { target, userInfo in
            if let target = target as? T {
                closure(target, userInfo)
            }
        }
    }
}

extension NotificationCenter {
    static let closures = NotificationCenter()
}

private class ClosureActionWrapper {
    weak var owner: AnyObject?
    var observers: [Notification.Name: NSObjectProtocol] = [:]
    var closures: [Notification.Name: (AnyObject, [AnyHashable: Any]?) -> Void] = [:]
    
    deinit {
        dispose()
    }
        
    func dispose() {
        observers.forEach {
            NotificationCenter.closures.removeObserver($0.value)
        }
        observers.removeAll()
        closures.removeAll()
    }
    
    func observe(name: Notification.Name, closure: @escaping (_ target: AnyObject, _ userInfo: [AnyHashable: Any]?) -> Void) {
        if let old = observers[name] {
            NotificationCenter.closures.removeObserver(old)
        }
        let ob = NotificationCenter.closures.addObserver(forName: name, object: nil, queue: nil) { [weak self] notify in
            guard let self = self, let owner = self.owner else {
                self?.dispose()
                return
            }
            guard (notify.object as? AnyObject) === owner else {
                return
            }
            self.closures[name]?(owner, notify.userInfo)
        }
        observers[name] = ob
        closures[name] = closure
    }
}

private var closureKey: Void?
private extension NSObject {
    var closureWrapper: ClosureActionWrapper {
        if let old = objc_getAssociatedObject(self, &closureKey) as? ClosureActionWrapper {
            return old
        }
        let new = ClosureActionWrapper()
        objc_setAssociatedObject(self, &closureKey, new, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return new
    }
}
