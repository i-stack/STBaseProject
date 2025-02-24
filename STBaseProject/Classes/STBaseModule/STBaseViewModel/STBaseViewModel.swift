//
//  STBaseViewModel.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

public enum STBaseError: LocalizedError {
    case success
    case origin(error: Error)
    case originErrorDescription(reason: String)
    
    var errorDescription: String {
        switch self {
        case .success:
            return "success"
        case .origin(error: let error):
            return error.localizedDescription
        case .originErrorDescription(reason: let reason):
            return reason
        }
    }
}

open class STBaseViewModel: NSObject {
    
}
