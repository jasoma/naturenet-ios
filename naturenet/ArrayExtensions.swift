//
//  ArrayExtensions.swift
//  NatureNet
//
//  Created by Jason Maher on 2/8/16.


/// Filters any `nil` elements from an array of optionals.
///
/// - parameter array: the array to filter.
/// - returns: the filtered array without the optional typing and no nil elements, may be
///            empty if the array was composed entirely of `nil`.
public func nonnil<T>(array: [T?]) -> [T] {
    return array.filter({ $0 != nil }).map({ $0! })
}