//
//  ApiTests.swift
//  StudKitTests
//
//  Created by Steffen Ryll on 27.07.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import XCTest
@testable import StudKit

final class ApiTests: XCTestCase {
    private let api = MockApi<TestRoutes>(baseUrl: URL(string: "https://example.com")!)

    func testRequestDecoded_Request_Value() {
        api.requestDecoded(.object) { (result: Result<Test>) in
            XCTAssertTrue(result.isSuccess)
            XCTAssertEqual(result.value?.id, "42")
        }
    }
}
