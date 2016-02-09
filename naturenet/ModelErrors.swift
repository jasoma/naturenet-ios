//
//  ModelErrors.swift
//  NatureNet
//
//  Created by Jason Maher on 2/9/16.
//
//

import Foundation

/// Collection of errors that can occur when dealing with models locally
/// or with response from the server.
enum ModelErrors: ErrorType {

    /// Not enough data is present to create a model instance. Contains the dictionary
    /// that was used to attempt a creation.
    case IncompleteData(NSDictionary)

    /// The response from the server was not what the model expected.
    case CouldNotReadResponse(Any)

    /// Too many matching records were found during an `NNModel.findOne` call. All matching
    /// records are attached.
    case NoUniqueRecord([NNModel])

    /// A save was attempted on an instance that was not linked to any context.
    case NoAssociatedContext

    /// Device has no internet access
    case NotConnected
}