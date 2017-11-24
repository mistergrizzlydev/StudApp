//
//  Semester+StudIp.swift
//  StudKit
//
//  Created by Steffen Ryll on 08.09.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import CoreData

extension Semester {
    public static func update(in context: NSManagedObjectContext, handler: @escaping ResultHandler<[Semester]>) {
        let studIp = ServiceContainer.default[StudIpService.self]
        studIp.api.requestCompleteCollection(.semesters) { (result: Result<[SemesterResponse]>) in
            Semester.update(using: result, in: context, handler: handler)

            NSFileProviderManager.default.signalEnumerator(for: .rootContainer) { _ in }
            NSFileProviderManager.default.signalEnumerator(for: .workingSet) { _ in }
        }
    }

    public func setHidden(_ hidden: Bool) {
        state.isHidden = hidden
        try? managedObjectContext?.saveWhenChanged()

        NSFileProviderManager.default.signalEnumerator(for: .rootContainer) { _ in }
        NSFileProviderManager.default.signalEnumerator(for: .workingSet) { _ in }
    }
}