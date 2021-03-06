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

@testable import StudKit

final class StudKitTestsServiceProvider: StudKitServiceProvider {
    override func provideReachabilityService() -> ReachabilityService {
        return ReachabilityService()
    }

    override func provideCoreDataService() -> CoreDataService {
        return CoreDataService(modelName: "StudKit", appGroupIdentifier: App.groupIdentifier, inMemory: true)
    }

    override func provideStudIpService() -> StudIpService {
        let api = MockApi<StudIpRoutes>(baseUrl: URL(string: "https://example.com")!)
        return StudIpService(api: api)
    }
}
