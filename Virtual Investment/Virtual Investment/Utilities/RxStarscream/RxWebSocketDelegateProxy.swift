//
//  RxWebSocketDelegateProxy.swift
//  Virtual Investment
//
//  Created by sangho Cho on 2021/03/28.
//

import RxSwift
import RxCocoa
import Starscream

public class RxWebSocketDelegateProxy: DelegateProxy<WebSocket, WebSocketDelegate>, DelegateProxyType, WebSocketDelegate {

  // MARK: Properties

  fileprivate let didReceiveSubject = PublishSubject<WebSocketEvent>()


  // MARK: Initialzing

  deinit {
    self.didReceiveSubject.onCompleted()
  }


  // MARK: DelegateProxyType

  public static func registerKnownImplementations() {
    self.register { (socket) -> RxWebSocketDelegateProxy in
      RxWebSocketDelegateProxy(parentObject: socket, delegateProxy: self)
    }
  }

  public static func currentDelegate(for object: WebSocket) -> WebSocketDelegate? {
    object.delegate
  }

  public static func setCurrentDelegate(_ delegate: WebSocketDelegate?, to object: WebSocket) {
    object.delegate = delegate
  }


  // MARK: WebSocketDelegate

  public func didReceive(event: WebSocketEvent, client: WebSocket) {
    self.didReceiveSubject.onNext(event)
  }
}

extension WebSocket: ReactiveCompatible { }
extension Reactive where Base: WebSocket {
  public var didReceive: ControlEvent<WebSocketEvent> {
    let soruce = RxWebSocketDelegateProxy.proxy(for: self.base).didReceiveSubject
    return ControlEvent(events: soruce)
  }
}
