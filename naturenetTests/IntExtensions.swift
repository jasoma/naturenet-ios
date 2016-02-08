//
//  IntExtensions.swift
//  NatureNet
//
//  Created by Jason Maher on 2/8/16.
//
//

import Foundation

extension Int {

    /// Run a block a number of times
    func times(block: () -> ()) {
        for _ in 1...self {
            block()
        }
    }

    /// Run a block a number of times
    func timesWithCount(block: (Int) -> ()) {
        for i in 1...self {
            block(i)
        }
    }

}