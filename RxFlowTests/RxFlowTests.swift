//
//  RxFlowTests.swift
//  RxFlow
//
//  Created by Anders Carlsson on 22/02/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import XCTest
import RxFlow
import SwiftyJSON
import RxSwift
@testable import RxFlow

class RxFlowTests: XCTestCase {
    
    private let getURL = "http://httpbin.org/get"
    private let postURL = "http://httpbin.org/post"
    private let putURL = "http://httpbin.org/put"
    private let deleteURL = "http://httpbin.org/delete"
    
    
    private var disposeBag = DisposeBag()
    
    override func setUp() {
        disposeBag = DisposeBag()
    }
    
    func testGet() {
        
        let expectation = expectationWithDescription("Get should be successful")
        var result: JSON = nil
        
        RxFlow().target(getURL).get().subscribeNext { json, _ in
            result = json
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        XCTAssertNotNil(result)
    }
    
    func testPost() {
        
        let expectation = expectationWithDescription("Post should be successful")
        let payload = "1001"
        let data = "payload=\(payload)".dataUsingEncoding(NSUTF8StringEncoding)!
        var result: JSON = nil
        
        RxFlow().target(postURL).post(data, parser: SwiftyJSONParser).subscribeNext { json, _ in
            result = json
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        XCTAssertEqual(result["form"]["payload"].string, payload)
    }
    
    func testPut() {
        
        let expectation = expectationWithDescription("Put should be successful")
        let data = "payload".dataUsingEncoding(NSUTF8StringEncoding)!
        var result: JSON = nil
        
        RxFlow().target(putURL).put(data, parser: SwiftyJSONParser).subscribeNext { json, _ in
            result = json
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        XCTAssertEqual(result["data"].string, "payload")
    }
    
    func testDelete() {
        
        let expectation = expectationWithDescription("Delete should be successful")
        var result = ""
        
        RxFlow().target(deleteURL).delete().subscribeNext { response, _ in
            result = response
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        XCTAssertNotNil(result)
    }
    
    func testSingleQueryParameter() {
        
        let expectation = expectationWithDescription("Added query parameter should be returned")
        var result: JSON = nil
        
        RxFlow().target(getURL).parameter("name", value: "value").get().subscribeNext { json, _ in
            result = json
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        
        XCTAssertEqual(result["args"]["name"].string, "value")
    }
    
    func testMultipleQueryParamaters() {
        
        let expectation = expectationWithDescription("Added query parameters should be returned")
        let parameters = ["name1": "value1", "name2": "value2"]
        var result: JSON = nil
        
        RxFlow().target(getURL).parameters(parameters).get().subscribeNext { json, _ in
            result = json
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        
        XCTAssertEqual(result["args"]["name1"], "value1")
        XCTAssertEqual(result["args"]["name2"], "value2")
    }
    
    func testSingleHeader() {
        
        let expectation = expectationWithDescription("Added header should be returned")
        var result: JSON = nil
        
        RxFlow().target(getURL).header("Api-Key", value: "12345").get().subscribeNext { json, _ in
            result = json
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        
        XCTAssertEqual(result["headers"]["Api-Key"].string, "12345")
    }
    
    func testMultipleHeaders() {
        
        let expectation = expectationWithDescription("Added headers should be returned")
        let headers = ["Key1": "Value1", "Key2": "Value2"]
        var result: JSON = nil
        
        RxFlow().target(getURL).headers(headers).get().subscribeNext { json, _ in
            result = json
            expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        
        XCTAssertEqual(result["headers"]["Key1"].string, "Value1")
        XCTAssertEqual(result["headers"]["Key2"].string, "Value2")
    }
    
    func testCommunicationError() {
        
        let expectation = self.expectationWithDescription("Invalid url should result in CommunicationError")
        
        RxFlow().target("invalid_address").get().subscribeError { error in
            do { throw error }
            catch FlowError.CommunicationError(_) { expectation.fulfill() }
            catch { }
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
    }
    
    func testUnsupportedStatusCode() {
        
        let expectation = self.expectationWithDescription("Status code 400 should result in UnsupportedStatusCode")
        
        RxFlow().target("https://httpbin.org/status/400").get().subscribeError { error in
            do { throw error }
            catch FlowError.UnsupportedStatusCode(_) { expectation.fulfill() }
            catch { }
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
    }
    
    func testParsingIsNotPerformedOnMainThread() {
        
        let expectation = self.expectationWithDescription("Parsing should not be performed on main thread")
        var isMain = true
        
        RxFlow().target(getURL).get { (data) -> Void in
            isMain = NSThread.isMainThread()
            }.subscribeNext { _, _ in
                expectation.fulfill()
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
        XCTAssertFalse(isMain)
    }
    
    func testParseError() {
        
        let expectation = expectationWithDescription("")
        
        RxFlow().target(getURL).get { data in
            throw FlowError.ParseError(nil)
            }.subscribeError { error in
                do { throw error }
                catch FlowError.ParseError(_) { expectation.fulfill() }
                catch { }
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
    }
    
    func testRetry() {
        
        let expectation = expectationWithDescription("Retry should complete")
        let retries = 3
        
        RxFlow().target("https://httpbin.org/status/400", retries: retries).get().subscribeError { error in
            switch error {
            case FlowError.RetryFailed(_, let attemptsDone, let attemptsLeft):
                if attemptsDone == retries && attemptsLeft == 0 {
                    expectation.fulfill()
                }
            default: return
            }
            }.addDisposableTo(disposeBag)
        
        waitForExpectation()
    }
    
    // MARK: Private helpers
    
    private func waitForExpectation() {
        waitForExpectationsWithTimeout(10.0, handler: nil)
    }
}

