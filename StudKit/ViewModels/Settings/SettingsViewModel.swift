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

import UserNotifications

public final class SettingsViewModel: NSObject {
    private let coreDataService = ServiceContainer.default[CoreDataService.self]
    private let hookService = ServiceContainer.default[HookService.self]
    private let studIpService = ServiceContainer.default[StudIpService.self]
    private let storageService = ServiceContainer.default[StorageService.self]

    public override init() {
        super.init()
        areNotificationsEnabled = storageService.defaults.areNotificationsEnabled
    }

    // MARK: - Downloads

    /// The total combined file sizes in the downloaded documents directory.
    public var sizeOfDownloadsDirectory: Int? {
        return FileManager.default
            .enumerator(at: BaseDirectories.downloads.url, includingPropertiesForKeys: [.fileSizeKey], options: [])?
            .compactMap { $0 as? URL }
            .compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]) }
            .compactMap { $0.fileSize }
            .reduce(0, +)
    }

    /// Delete all locally downloaded documents in the downloads and file provider directory.
    public func removeAllDownloads() throws {
        try storageService.removeAllDownloads()
        try File.fetch(in: coreDataService.viewContext).forEach { file in
            file.downloadedBy.removeAll()
            file.state.downloadedAt = nil
        }
        try coreDataService.viewContext.saveAndWaitWhenChanged()
    }

    // MARK: - Notifications

    public var supportsNotifications: Bool {
        return User.current?.organization.supportsNotifications ?? false
    }

    @objc public private(set) dynamic var allowsNotifications = false

    @objc public dynamic var areNotificationsEnabled = false {
        didSet {
            guard allowsNotifications else { return areNotificationsEnabled = false }

            storageService.defaults.areNotificationsEnabled = areNotificationsEnabled
            hookService.updateHooks()

            if #available(iOS 12, *) { return }

            hookService.requestAuthorization(options: hookService.userNotificationAuthorizationsOptions) {
                self.updateNotificationSettings()
            }
        }
    }

    public func updateNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.allowsNotifications = settings.authorizationStatus != .denied
                self.areNotificationsEnabled = self.areNotificationsEnabled && self.allowsNotifications
            }
        }
    }
}
