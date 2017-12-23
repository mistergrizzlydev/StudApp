//
//  CourseListViewModel.swift
//  StudKit
//
//  Created by Steffen Ryll on 03.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import CoreData

/// Manages a list of courses in the semester given.
///
/// In order to display initial data, you must call `fetch()`. Changes in the view context are automatically propagated to
/// `delegate`. This class also supports updating data from the server.
public final class CourseListViewModel: NSObject {
    private let coreDataService = ServiceContainer.default[CoreDataService.self]
    private let semester: Semester
    private let respectsCollapsedState: Bool

    public weak var delegate: DataSourceSectionDelegate?

    /// Creates a new course list view model managing the given semester's courses.
    public init(semester: Semester, respectsCollapsedState: Bool = false) {
        self.semester = semester
        self.respectsCollapsedState = respectsCollapsedState
        isCollapsed = semester.state.isCollapsed
        super.init()

        controller.delegate = self
    }

    private(set) lazy var controller: NSFetchedResultsController<CourseState>
        = NSFetchedResultsController(fetchRequest: semester.coursesFetchRequest,
                                     managedObjectContext: coreDataService.viewContext, sectionNameKeyPath: nil, cacheName: nil)

    /// Fetches initial data.
    public func fetch() {
        controller.fetchRequest.predicate = isCollapsed && respectsCollapsedState
            ? NSPredicate(value: false)
            : semester.coursesFetchRequest.predicate
        try? controller.performFetch()
    }

    /// Updates data from the server.
    public func update(handler: ResultHandler<Void>? = nil) {
        coreDataService.performBackgroundTask { context in
            Course.update(in: context) { result in
                try? context.saveWhenChanged()
                try? self.coreDataService.viewContext.saveWhenChanged()
                handler?(result.replacingValue(()))
            }
        }
    }

    public var isCollapsed: Bool {
        didSet {
            guard isCollapsed != oldValue else { return }

            delegate?.dataWillChange(in: self)
            for (index, row) in enumerated() {
                delegate?.data(changedIn: row, at: index, change: .delete, in: self)
            }
            fetch()
            for (index, row) in enumerated() {
                delegate?.data(changedIn: row, at: index, change: .insert, in: self)
            }
            delegate?.dataDidChange(in: self)
        }
    }
}

// MARK: - Data Source Section

extension CourseListViewModel: DataSourceSection {
    public typealias Row = Course

    public var numberOfRows: Int {
        return controller.sections?.first?.numberOfObjects ?? 0
    }

    public subscript(rowAt index: Int) -> Course {
        return controller.object(at: IndexPath(row: index, section: 0)).course
    }
}

// MARK: - Fetched Results Controller Delegate

extension CourseListViewModel: NSFetchedResultsControllerDelegate {
    public func controllerWillChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.dataWillChange(in: self)
    }

    public func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.dataDidChange(in: self)
    }

    public func controller(_: NSFetchedResultsController<NSFetchRequestResult>, didChange object: Any, at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let state = object as? CourseState else { fatalError() }
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { return }
            delegate?.data(changedIn: state.course, at: indexPath.row, change: .insert, in: self)
        case .delete:
            guard let indexPath = indexPath else { return }
            delegate?.data(changedIn: state.course, at: indexPath.row, change: .delete, in: self)
        case .update:
            guard let indexPath = indexPath else { return }
            delegate?.data(changedIn: state.course, at: indexPath.row, change: .update(state.course), in: self)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            delegate?.data(changedIn: state.course, at: indexPath.row, change: .move(to: newIndexPath.row), in: self)
        }
    }
}
