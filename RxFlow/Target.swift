//
//  Target.swift
//  RxFlow
//
//  Created by Anders Carlsson on 22/02/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift

//// Default UTF8StringParser
public let UTF8StringParser: (NSData) throws -> (String) = {
    data in

    guard let result = String(data: data, encoding: NSUTF8StringEncoding) else {
        throw FlowError.ParseError(nil)
    }
    return result
}

//// SwiftyJSON parser
public let SwiftyJSONParser: (NSData) -> (JSON) = {
    data in return JSON(data: data)
}

//MARK: HTTP Methods

private enum HTTPMethod: String {
    case GET, PUT, POST, DELETE, HEAD, OPTIONS, PATCH
}

public final class Target {

    private static let background = ConcurrentDispatchQueueScheduler.init(globalConcurrentQueueQOS: .Background)

    public typealias Headers = [String:String]

    private let url: String
    private var session: NSURLSession
    private let retries: Int
    private let delay: Int
    private lazy var parameters: Array<NSURLQueryItem> = []
    private lazy var headers: [String:String] = [:]

    init(url: String, session: NSURLSession, retries: Int, delay: Int) {
        self.url = url
        self.session = session
        self.retries = retries
        self.delay = delay
    }

    // MARK: Value collector methods

    public func header(name: String, value: String) -> Target {
        headers[name] = value
        return self
    }

    public func headers(headers: [String:String]) -> Target {
        for (name, value) in headers {
            self.headers[name] = value
        }
        return self
    }

    public func parameter(name: String, value: String) -> Target {
        parameters.append(NSURLQueryItem(name: name, value: value))
        return self
    }

    public func parameters(parameters: [String:String]) -> Target {
        for (name, value) in parameters {
            self.parameters.append(NSURLQueryItem(name: name, value: value))
        }
        return self
    }

    // TODO:
    // - add request body serializer support

    // MARK: RX request methods

    public func get() -> Observable<(JSON, Headers)> {
        return get(SwiftyJSONParser)
    }

    public func get<T>(parser: (NSData) throws -> T) -> Observable<(T, Headers)> {
        return parse(requestForMethod(.GET), parser: parser)
    }

    public func post(data: NSData) -> Observable<(String, Headers)> {
        return post(data, parser: UTF8StringParser)
    }

    public func post<T>(data: NSData, parser: NSData throws -> T) -> Observable<(T, Headers)> {
        return parse(requestForMethod(.POST, body: data), parser: parser)
    }

    public func put<T>(data: NSData, parser: (NSData) throws -> T) -> Observable<(T, Headers)> {
        return parse(requestForMethod(.PUT, body: data), parser: parser)
    }

    public func put(data: NSData) -> Observable<(String, Headers)> {
        return put(data, parser: UTF8StringParser)
    }

    public func delete<T>(parser: (NSData) throws -> T) -> Observable<(T, Headers)> {
        return parse(requestForMethod(.DELETE), parser: parser)
    }

    public func delete() -> Observable<(String, Headers)> {
        return delete(UTF8StringParser)
    }

    public func head() -> Observable<Headers> {
        return request(requestForMethod(.HEAD)).map {
            _, http in return http.headers()
        }.observeOn(MainScheduler.instance)
    }

    public func options<T>(parser: (NSData) throws -> T) -> Observable<(T, Headers)> {
        return parse(requestForMethod(.OPTIONS), parser: parser)
    }

    public func options() -> Observable<(JSON, Headers)> {
        return options(SwiftyJSONParser)
    }

    public func patch<T>(data: NSData, parser: (NSData) throws -> T) -> Observable<(T, Headers)> {
        return parse(requestForMethod(.PATCH, body: data), parser: parser)
    }

    public func patch(data: NSData) -> Observable<(String, Headers)> {
        return patch(data, parser: UTF8StringParser)
    }

    // MARK: Private
    private func parse<T>(request: NSURLRequest, parser: (NSData) throws -> T) -> Observable<(T, Headers)> {
        return self.request(request).map {
            data, http in return (try parser(data), http.headers())
        }.observeOn(MainScheduler.instance)
    }

    private func request(request: NSURLRequest) -> Observable<(NSData, NSHTTPURLResponse)> {

        let observable = Observable<(NSData, NSHTTPURLResponse)>.create {
            observer in

            let task = self.session.dataTaskWithRequest(request) {
                data, response, error in

                // Communication Error
                guard let response = response, data = data else {
                    observer.onError(FlowError.CommunicationError(error))
                    return
                }

                // Non Http Response Error
                guard let http = response as? NSHTTPURLResponse else {
                    observer.onError(FlowError.NonHttpResponse(response))
                    return
                }

                // Unsupported Status Code Error
                guard http.isSuccessResponse() else {
                    observer.onError(FlowError.UnsupportedStatusCode(http))
                    return
                }

                observer.onNext(data, http)
                observer.onCompleted()
            }

            task.resume()

            return AnonymousDisposable {
                task.cancel()
            }
}.observeOn(Target.background)

        // Only add retry handler if it is requested
        return retries == 0 ? observable : observable.retryWhen(retryHandler)
    }

    // See: http://blog.danlew.net/2016/01/25/rxjavas-repeatwhen-and-retrywhen-explained/
    private func retryHandler(errors: Observable<ErrorType>) -> Observable<Int> {

        var attemptsLeft = self.retries
        var attemptsDone = 0;

        return errors.flatMap {
            (error) -> Observable<Int> in

            if attemptsLeft <= 0 {
                return Observable.error(FlowError.RetryFailed(error, self.retries, attemptsLeft))
            }

            switch error {
                case FlowError.CommunicationError(_), FlowError.UnsupportedStatusCode(_):

                    attemptsDone += 1
                    NSThread.sleepForTimeInterval(Double(self.delay * attemptsDone))
                    attemptsLeft -= 1

                    return Observable.just(0)
                default: return Observable.error(error)
            }
        }
    }

    private func requestForMethod(method: HTTPMethod, body: NSData? = nil) -> NSURLRequest {

        let urlComponent = NSURLComponents(string: url)!
        urlComponent.queryItems = parameters

        let request = NSMutableURLRequest(URL: urlComponent.URL!)
        request.allHTTPHeaderFields = headers
        request.HTTPMethod = method.rawValue
        request.HTTPBody = body

        return request
    }
}