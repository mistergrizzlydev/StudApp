//
//  UpdatableTests.swift
//  StudKitTests
//
//  Created by Steffen Ryll on 28.07.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import CoreData
import XCTest
@testable import StudKit

final class UpdatableTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUp() {
        context = StudKitTestsServiceProvider(currentTarget: .tests).provideCoreDataService().viewContext

        try! CourseResponse(id: "0", title: "A").coreDataModel(in: context)
        try! CourseResponse(id: "1", title: "Course 2").coreDataModel(in: context)

        try! FileResponse(fileId: "0", name: "file.pdf", coursePath: "$1", title: "File").coreDataModel(in: context)

        try! context.save()
    }

    func testUpdate_Nil_Failure() {
        let result = Result<[CourseResponse]>.failure(nil)
        Course.update(using: result, in: context) { courseResult in
            try! self.context.save()
            XCTAssertTrue(courseResult.isFailure)
            XCTAssertEqual(try! Course.fetch(in: self.context).count, 2)
        }
    }

    func testUpdate_Add_Added() {
        XCTAssertEqual(try! Course.fetch(in: context).count, 2)

        let result = Result.success([CourseResponse(id: "2", title: "C")])
        Course.update(using: result, in: context) { courseResult in
            try! self.context.save()

            XCTAssertTrue(courseResult.isSuccess)
            XCTAssertEqual(try! Course.fetch(in: self.context).count, 3)
        }
    }

    func testMerge_Courses_Merged() {
        try! CourseResponse(id: "2", title: "Course").coreDataModel(in: context)
        try! context.save()
        try! CourseResponse(id: "2", title: "Updated Course").coreDataModel(in: context)
        try! context.save()

        let course = try! Course.fetch(byId: "2", in: context)
        XCTAssertEqual(course?.title, "Updated Course")
    }

    func testUpdate_Update_Updated() {
        XCTAssertEqual(try! Course.fetch(in: context).count, 2)

        let result = Result.success([CourseResponse(id: "1", title: "Updated Course 2")])
        Course.update(using: result, in: context) { courseResult in
            try! self.context.save()
            let course2 = try! Course.fetch(byId: "1", in: self.context)

            XCTAssertTrue(courseResult.isSuccess)
            XCTAssertEqual(try! Course.fetch(in: self.context!).count, 2)
            XCTAssertEqual(course2?.title, "Updated Course 2")
            XCTAssertEqual(course2?.files.count, 1)
        }
    }
}
