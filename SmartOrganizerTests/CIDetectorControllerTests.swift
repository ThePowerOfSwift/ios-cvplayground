//
//  SmartOrganizerTests.swift
//  SmartOrganizerTests
//
//  Created by iwat on 11/8/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import XCTest

class CIDetectorControllerTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testExample() {
		// This is an example of a functional test case.
		// Use XCTAssert and related functions to verify your tests produce the correct results.
	}

	func testPerspectiveTransform() {
		let controller = CIDetectorController()
		let result = controller.perspectiveTransform(161, 31, 63, 72, 151, 216, 269, 142, 0, 0, 220, 0, 220, 300, 0, 300)
		XCTAssertEqualWithAccuracy(result.a, -1.968966095001718, accuracy: 0.000001)
		XCTAssertEqualWithAccuracy(result.b, 1.915750795136804, accuracy: 0.000001)
		XCTAssertEqualWithAccuracy(result.c, 1.180349313569417, accuracy: 0.000001)
		XCTAssertEqualWithAccuracy(result.d, 2.821322749507383, accuracy: 0.000001)
		XCTAssertEqualWithAccuracy(result.tx, 257.6152666460356, accuracy: 0.000001)
		XCTAssertEqualWithAccuracy(result.ty, -277.4972447194046, accuracy: 0.000001)
	}

	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock {
			// Put the code you want to measure the time of here.
		}
	}

}
