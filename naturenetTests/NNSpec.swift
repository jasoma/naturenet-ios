//
//  NNSpec.swift
//  NatureNet
//
//  Created by Jason Maher on 2/8/16.
//
//

import Foundation
import Quick

/// Base class for our tests. Provides some utility methods around `XCTestExpectation` which is more reliable
/// in async tests then Nimble's `expect().toEventuall()`.
class NNSpec: QuickSpec {

    /// Timeout for tests using `waitDone`
    var timeout: NSTimeInterval = 1

    /// Creates a generic expectation that can be manually fulfilled later.
    func asyncLatch(f: String = __FUNCTION__, l: Int = __LINE__) -> XCTestExpectation {
        return expectationWithDescription("\(f)[\(l)] async operations complete")
    }

    /// Wait for all expectations to complete.
    func waitDone() {
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
}