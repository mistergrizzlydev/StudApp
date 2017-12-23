//
//  SemesterListViewModel.swift
//  StudKit
//
//  Created by Steffen Ryll on 11.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import CoreData

/// Manages a list of semesters.
///
/// In order to display initial data, you must call `fetch()`. Changes in the view context are automatically propagated to
/// `delegate`. This class also supports updating data from the server.
public final class SemesterListViewModel: NSObject {
    private let coreDataService = ServiceContainer.default[CoreDataService.self]
    private let studIpService = ServiceContainer.default[StudIpService.self]
    private var fetchRequest: NSFetchRequest<SemesterState>

    public weak var delegate: DataSourceSectionDelegate?

    /// Creates a new semester list view model managing the semesters in returned by the request given, which defaults to all
    /// semesters.
    public init(fetchRequest: NSFetchRequest<SemesterState> = Semester.sortedFetchRequest) {
        self.fetchRequest = fetchRequest
        super.init()

        controller.delegate = self
    }

    private(set) lazy var controller: NSFetchedResultsController<SemesterState>
        = NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: coreDataService.viewContext,
                                     sectionNameKeyPath: nil, cacheName: nil)

    /// Fetches initial data.
    public func fetch() {
        try? controller.performFetch()
    }

    /// Updates data from the server.
    public func update(enforce: Bool = false, handler: ResultHandler<Void>? = nil) {
        coreDataService.performBackgroundTask { context in
            Semester.update(in: context, enforce: enforce) { result in
                try? context.saveWhenChanged()
                try? self.coreDataService.viewContext.saveWhenChanged()
                handler?(result.replacingValue(()))
            }
        }
    }
}

// MARK: - Data Source Section

extension SemesterListViewModel: DataSourceSection {
    public typealias Row = Semester

    public var numberOfRows: Int {
        return controller.sections?.first?.numberOfObjects ?? 0
    }

    public subscript(rowAt index: Int) -> Semester {
        return controller.object(at: IndexPath(row: index, section: 0)).semester
    }
}

// MARK: - Fetched Results Controller Delegate

extension SemesterListViewModel: NSFetchedResultsControllerDelegate {
    public func controllerWillChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.dataWillChange(in: self)
    }

    public func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.dataDidChange(in: self)
    }

    public func controller(_: NSFetchedResultsController<NSFetchRequestResult>, didChange object: Any, at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let state = object as? SemesterState else { fatalError() }
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { return }
            delegate?.data(changedIn: state.semester, at: indexPath.row, change: .insert, in: self)
        case .delete:
            guard let indexPath = indexPath else { return }
            delegate?.data(changedIn: state.semester, at: indexPath.row, change: .delete, in: self)
        case .update:
            guard let indexPath = indexPath else { return }
            delegate?.data(changedIn: state.semester, at: indexPath.row, change: .update(state.semester), in: self)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            delegate?.data(changedIn: state.semester, at: indexPath.row, change: .move(to: newIndexPath.row), in: self)
        }
    }
}
