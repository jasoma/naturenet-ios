//
//  Random.swift
//  NatureNet
//
//  Created by Jason Maher on 2/8/16.
//
//

import Foundation

/// A collection of functions for generating random values. For all functions that return `Int` the random
/// value will not be above `UInt32.max` since `arc4random_uniform()` is being used to generate the value.
/// Int is used as the return for convenience.
public struct Random {

    /// - returns: a random Int between 0 and UInt32.max.
    public static func int() -> Int {
        return Int(arc4random_uniform(UInt32.max))
    }

    /// - returns: a random Int in the range specified.
    public static func int(range: Range<Int>) -> Int {
        return Int(arc4random_uniform(UInt32(range.endIndex - range.startIndex))) + range.startIndex
    }

    /// - returns: a random boolean.
    public static func coin() -> Bool {
        return int(0...1) == 0
    }

    /// - returns: a random string of lowercase characters and numbers
    public static func alphanumeric(length: Int = 10) -> String {
        let chars = [Character]("abcdefghijklmnopqrstuvwxyz0123456789".characters)
        var string = ""
        for _ in 0..<length {
            string.append(sample(chars))
        }
        return string
    }
    
}

func sample<T>(array: [T]) -> T {
    return array[Random.int(0..<array.count)]
}