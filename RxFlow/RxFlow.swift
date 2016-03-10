//
//  RxFlow.swift
//  RxFlow
//
//  Created by Anders Carlsson on 22/02/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import Foundation

// MARK: RxFlow

public final class RxFlow {

    private let session: NSURLSession
    private let defaultHeaders: [String:String]

    public convenience init(defaultHeaders: [String:String] = [:]) {
        self.init(session: NSURLSession.sharedSession(), defaultHeaders: defaultHeaders)
    }

    public convenience init(configuration: NSURLSessionConfiguration, defaultHeaders: [String:String] = [:]) {
        let session = NSURLSession(configuration: configuration)
        self.init(session: session, defaultHeaders: defaultHeaders)
    }

    public init(session: NSURLSession, defaultHeaders: [String:String] = [:]) {
        self.session = session
        self.defaultHeaders = defaultHeaders
    }

    public func target(url: String, retries: Int = 0, delay: Int = 0) -> Target {
        return Target(url: url, session: session, retries: retries, delay: delay, headers: defaultHeaders)
    }

    func invalidateSession() {
        self.session.invalidateAndCancel()
    }
}

// MARK: FlowError

public enum FlowError: ErrorType {

    case CommunicationError(ErrorType?)
    case UnsupportedStatusCode(NSHTTPURLResponse)
    case ParseError(ErrorType?)
    case NonHttpResponse(NSURLResponse)
    case RetryFailed(ErrorType?, Int, Int)
}


// MARK: NSHTTPURLResponse - Extension

public extension NSHTTPURLResponse {

    public func isSuccessResponse() -> Bool {
        return (self.statusCode / 100) == 2
    }

    public func headerValueForKey(key: String) -> String? {
        return self.allHeaderFields[key] as? String
    }

    public func headers() -> [String:String] {

        var headers:[String:String] = [:]

        for (key, value) in self.allHeaderFields {
            headers[String(key)] = String(value)
        }

        return headers
    }
}