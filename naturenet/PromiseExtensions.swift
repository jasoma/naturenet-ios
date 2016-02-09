//
//  PromiseExtensions.swift
//  NatureNet
//
//  Created by Jason Maher on 2/9/16.
//
//

import Foundation
import PromiseKit

extension Promise {

    /// Add an equivalent `then(on:)` function that uses our `Dispatch` enum.
    func then<U>(on dispatch: Dispatch, _ body: (T) throws -> Promise<U>) -> Promise<U> {
        return then(on: dispatch.queue, body)
    }

    /// Add an equivalent `then(on:)` function that uses our `Dispatch` enum.
    func then<U>(on dispatch: Dispatch, _ body: (T) throws -> U) -> Promise<U> {
        return then(on: dispatch.queue, body)
    }

    /// Add an error handler the alows the callback queue to be specified.
    func error(on dispatch: Dispatch, _ body: ErrorType -> ()) {
        self.error({ cause in
            dispatch ~> { body(cause) }
        })
    }

}