//
//  Organization.swift
//  StudKit
//
//  Created by Steffen Ryll on 22.02.18.
//  Copyright © 2018 Steffen Ryll. All rights reserved.
//

import CoreData

@objc(Organization)
public final class Organization: NSManagedObject, CDCreatable, CDIdentifiable, CDSortable {

    // MARK: Identification

    public static let entity = ObjectIdentifier.Entites.organization

    @NSManaged public var id: String

    @NSManaged public var title: String

    // MARK: Managing API Access

    @NSManaged private var apiUrlString: String

    /// Remark: - This is not of type `URI` in order to support iOS 10.
    var apiUrl: URL {
        get {
            guard let url = URL(string: apiUrlString) else { fatalError("Cannot construct API URL") }
            return url
        }
        set { apiUrlString = newValue.absoluteString }
    }

    // MARK: Managing Content

    @NSManaged public var announcements: Set<Announcement>

    @NSManaged public var courses: Set<Course>

    @NSManaged public var events: Set<Event>

    @NSManaged public var files: Set<File>

    @NSManaged public var semesters: Set<Semester>

    @NSManaged public var users: Set<User>

    // MARK: Managing Metadata

    @NSManaged public var iconData: Data?

    @NSManaged public var iconThumbnailData: Data?

    // MARK: - Sorting

    static let defaultSortDescriptors = [
        NSSortDescriptor(keyPath: \Organization.title, ascending: true),
    ]

    // MARK: - Describing

    public override var description: String {
        return "<Organization id: \(id), title: \(title)>"
    }
}

// MARK: - Persisting Credentials

extension Organization {
    private enum KeychainKeys: String {
        case consumerKey, consumerSecret
    }

    var consumerKey: String? {
        get {
            let keychainService = ServiceContainer.default[KeychainService.self]
            return try? keychainService.password(for: objectIdentifier.rawValue, account: KeychainKeys.consumerKey.rawValue)
        }
        set {
            let keychainService = ServiceContainer.default[KeychainService.self]
            guard let newValue = newValue else {
                try? keychainService.delete(from: objectIdentifier.rawValue, account: KeychainKeys.consumerKey.rawValue)
                return
            }
            try? keychainService.save(password: newValue, for: objectIdentifier.rawValue, account: KeychainKeys.consumerKey.rawValue)
        }
    }

    var consumerSecret: String? {
        get {
            let keychainService = ServiceContainer.default[KeychainService.self]
            return try? keychainService.password(for: objectIdentifier.rawValue, account: KeychainKeys.consumerSecret.rawValue)
        }
        set {
            let keychainService = ServiceContainer.default[KeychainService.self]
            guard let newValue = newValue else {
                try? keychainService.delete(from: objectIdentifier.rawValue, account: KeychainKeys.consumerSecret.rawValue)
                return
            }
            try? keychainService.save(password: newValue, for: objectIdentifier.rawValue, account: KeychainKeys.consumerSecret.rawValue)
        }
    }
}

// MARK: - Core Data Operations

extension Organization {
    public func fetchSemesters(from beginSemester: Semester? = nil, to endSemester: Semester? = nil,
                               in context: NSManagedObjectContext) throws -> [Semester] {
        let beginsAt = beginSemester?.beginsAt ?? .distantPast
        let endsAt = endSemester?.endsAt ?? .distantFuture
        let predicate = NSPredicate(format: "organization == %@ AND beginsAt >= %@ AND endsAt <= %@",
                                    self, beginsAt as CVarArg, endsAt as CVarArg)
        let request = Semester.fetchRequest(predicate: predicate, sortDescriptors: Semester.defaultSortDescriptors)
        return try context.fetch(request)
    }

    public var semesterStatesFetchRequest: NSFetchRequest<SemesterState> {
        return SemesterState.fetchRequest(predicate: NSPredicate(value: true),
                                          sortDescriptors: SemesterState.defaultSortDescriptors,
                                          relationshipKeyPathsForPrefetching: ["semester"])
    }

    public var visibleSemesterStatesFetchRequest: NSFetchRequest<SemesterState> {
        let predicate = NSPredicate(format: "organization == %@ AND isHidden == NO", self)
        return SemesterState.fetchRequest(predicate: predicate, sortDescriptors: SemesterState.defaultSortDescriptors,
                                          relationshipKeyPathsForPrefetching: ["semester"])
    }

    public func fetchVisibleSemesters(in context: NSManagedObjectContext) throws -> [Semester] {
        return try context.fetch(visibleSemesterStatesFetchRequest).map { $0.semester }
    }
}
