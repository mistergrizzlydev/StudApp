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

public protocol EventsContaining {
    var objectIdentifier: ObjectIdentifier { get }

    var title: String { get }

    var eventsPredicate: NSPredicate { get }

    func updateEvents(forced: Bool, completion: @escaping ResultHandler<Set<Event>>)
}

public extension EventsContaining {
    var eventsFetchRequest: NSFetchRequest<Event> {
        return Event.fetchRequest(predicate: eventsPredicate, sortDescriptors: Event.defaultSortDescriptors)
    }
}
