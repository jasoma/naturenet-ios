//
//  Dispatch.swift
//  NatureNet
//
//  Created by Jason Maher on 2/6/16.

import Foundation

/// A wrapper around the default GCD queues created for each application. Enum members
/// are used together with the threading operator to run tasks on different queues.
/// All default queues except for the main queue are concurrent. Application specific
/// queues can be created and stored locally in a `Queue` case if necessary.
enum Dispatch {

    private static let main = dispatch_get_main_queue()
    private static let background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    private static let low = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    private static let high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

    /// The main dispatch queue.
    case Main

    /// The default priority background queue.
    case Background

    /// The default low priority background queue.
    case LowPriority

    /// The default high priority backgound queue.
    case HighPriority

    /// A generic case for application defined queues.
    case Queue(dispatch_queue_t)

    /// Access the underlying `dispatch_queue` for an enum value.
    var queue: dispatch_queue_t {
        switch self {
        case .Main:
            return Dispatch.main
        case .Background:
            return Dispatch.background
        case .LowPriority:
            return Dispatch.low
        case .HighPriority:
            return Dispatch.high
        case .Queue(let definedQueue):
            return definedQueue
        }
    }
}

/// The threading operator.
infix operator ~> {}

/// Run a task asynchronously on a dispatch queue.
///
/// - parameter dispatch: where to run the task.
/// - parameter task: the operation to perform on the queue.
func ~>(dispatch: Dispatch, task: () -> ()) {
    dispatch_async(dispatch.queue, task)
}

/// Run a task asynchronously on a dispatch queue.
///
/// - parameter queue: where to run the task.
/// - parameter task: the operation to perform on the queue.
func ~>(queue: dispatch_queue_t, task: () -> ()) {
    dispatch_async(queue, task)
}

/// A pseudo keyword function for launching tasks on the default background queue.
/// exactly equivalent to calling `Dispatch.Background ~> task`.
///
/// parameter task: the operation to run in the background.
func async(task: () -> ()) {
    Dispatch.background ~> task
}
