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
import CoreSpotlight
import MobileCoreServices

/// Course that a user can attend, e.g. a university class.
///
/// Besides containing some metadata such as a title and location, each course is alse the root node of a file structure.
@objc(Course)
public final class Course: NSManagedObject, CDCreatable, CDIdentifiable, CDSortable {

    // MARK: Identification

    public static let entity = ObjectIdentifier.Entites.course

    @NSManaged public var id: String

    /// Course number internal to Stud.IP that can also be used for identifying a course.
    @NSManaged public var number: String?

    @NSManaged public var title: String

    // MARK: Specifying Location

    @NSManaged public var organization: Organization

    /// As a course can span multiple semesters, there is a set of semesters. However, most courses exist in one semester only.
    /// It is also important to know that—if contained in semesters `A` and `C`—a course should also be contained in `B`.
    @NSManaged public var semesters: Set<Semester>

    // MARK: Managing Content

    @NSManaged public var announcements: Set<Announcement>

    @NSManaged public var events: Set<Event>

    @NSManaged public var files: Set<File>

    // MARK: Managing Metadata

    /// Identifier for this course's group, which determines the course's sorting and color.
    @NSManaged public var groupId: Int

    /// Describes where this course is held.
    @NSManaged public var location: String?

    @NSManaged public var state: CourseState

    @NSManaged public var subtitle: String?

    /// Short description of the course and summary of its contents.
    @NSManaged public var summary: String?

    // MARK: Managing Members

    /// Users who organize or teach this course.
    @NSManaged public var lecturers: Set<User>

    /// Users who attend this course.
    @NSManaged public var authors: Set<User>

    // MARK: - Life Cycle

    public required convenience init(createIn context: NSManagedObjectContext) {
        self.init(context: context)
        state = CourseState(createIn: context)
    }

    public override func prepareForDeletion() {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id]) { _ in }
        super.prepareForDeletion()
    }

    // MARK: - Sorting

    static let defaultSortDescriptors = [
        NSSortDescriptor(keyPath: \Course.groupId, ascending: true),
        NSSortDescriptor(keyPath: \Course.title, ascending: true),
    ]

    // MARK: - Describing

    public override var description: String {
        return "<Course id: \(id), semesters: \(semesters), title: \(title)>"
    }
}

// MARK: - Core Data Operations

extension Course {
    /// Request for fetching all announcements for this course.
    public var announcementsFetchRequest: NSFetchRequest<Announcement> {
        let predicate = NSPredicate(format: "%@ IN courses", self)
        return Announcement.fetchRequest(predicate: predicate, sortDescriptors: Announcement.defaultSortDescriptors)
    }

    /// Request for fetching all announcements for this course that are not expired.
    public var unexpiredAnnouncementsFetchRequest: NSFetchRequest<Announcement> {
        let predicate = NSPredicate(format: "%@ IN courses AND expiresAt >= %@", self, Date() as CVarArg)
        return Announcement.fetchRequest(predicate: predicate, sortDescriptors: Announcement.defaultSortDescriptors)
    }
}

// MARK: - Files Container

extension Course: FilesContaining {
    public var childFilesPredicate: NSPredicate {
        return NSPredicate(format: "course == %@ AND parent == NIL", self)
    }
}

// MARK: - Events Container

extension Course: EventsContaining {
    public var eventsPredicate: NSPredicate {
        return NSPredicate(format: "course == %@", self)
    }
}

// MARK: - Core Spotlight and Activity Tracking

extension Course {
    public var keywords: Set<String> {
        let courseKeywords = [number].compactMap { $0 }
        let lecturersKeywords = lecturers.flatMap { [$0.givenName, $0.familyName] }
        let semestersKeywords = semesters.map { $0.title }
        return Set(courseKeywords).union(lecturersKeywords).union(semestersKeywords)
    }

    public var searchableItemAttributes: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeFolder as String)

        attributes.displayName = title
        attributes.keywords = Array(keywords)
        attributes.relatedUniqueIdentifier = objectIdentifier.rawValue
        attributes.title = title

        attributes.contentDescription = summary

        return attributes
    }

    public var searchableItem: CSSearchableItem {
        return CSSearchableItem(uniqueIdentifier: objectIdentifier.rawValue, domainIdentifier: Course.entity.rawValue,
                                attributeSet: searchableItemAttributes)
    }

    public var userActivity: NSUserActivity {
        let activity = NSUserActivity(type: .course)
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.title = title
        activity.webpageURL = url
        activity.contentAttributeSet = searchableItemAttributes
        activity.keywords = keywords
        activity.objectIdentifier = objectIdentifier
        return activity
    }
}
