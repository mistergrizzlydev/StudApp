//
//  StudApp—Stud.IP to Go
//  Copyright © 2018, Steffen Ryll
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/.
//

import CoreData

public final class EventListViewModel: FetchedResultsControllerDataSource {
    public typealias Section = Date
    public typealias Row = Event

    private let coreDataService = ServiceContainer.default[CoreDataService.self]

    public private(set) lazy var fetchedResultControllerDelegateHelper = FetchedResultsControllerDelegateHelper(delegate: self)
    public weak var delegate: DataSourceDelegate?

    public let course: Course

    public init(course: Course) {
        self.course = course

        controller.delegate = fetchedResultControllerDelegateHelper
    }

    public private(set) lazy var controller: NSFetchedResultsController<Event> = NSFetchedResultsController(
        fetchRequest: course.eventsFetchRequest, managedObjectContext: coreDataService.viewContext,
        sectionNameKeyPath: "daysSince1970", cacheName: nil)

    public func section(from sectionInfo: NSFetchedResultsSectionInfo) -> Section? {
        return (sectionInfo.objects?.first as? Event)?.startsAt.startOfDay
    }

    public func fetch() {
        try? controller.performFetch()
    }

    public func update(completion: (() -> Void)? = nil) {
        coreDataService.performBackgroundTask { context in
            self.course.in(context)
                .updateEvents { _ in DispatchQueue.main.async { completion?() } }
        }
    }

    public func sectionIndex(for date: Date) -> Int? {
        return controller.sections?.index { self.section(from: $0) == date.startOfDay }
    }

    public var nowIndexPath: IndexPath? {
        let today = Date()

        let sectionIndex = enumerated()
            .filter { $0.element >= today.startOfDay }
            .first?
            .offset
        guard let section = sectionIndex else { return nil }

        let rowIndex = controller.sections?[section].objects?
            .enumerated()
            .filter { ($0.element as? Event)?.startsAt ?? .distantPast >= today }
            .first?
            .offset
        guard let row = rowIndex else { return IndexPath(row: 0, section: section) }

        return IndexPath(row: row, section: section)
    }
}
